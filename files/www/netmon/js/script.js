const el = {
  themeBtn: document.getElementById('themeBtn'),
  themeText: document.getElementById('themeText'),
  statsBtn: document.getElementById('statsBtn'),
  resetBtn: document.getElementById('resetBtn'),
  toast: document.getElementById('toast'),
  toastMsg: document.getElementById('toastMsg'),
  currentDate: document.getElementById('currentDate'),
  currentTime: document.getElementById('currentTime'),
  currentDay: document.getElementById('currentDay'),
  imageContainer: document.getElementById('imageContainer'),
  statsModal: document.getElementById('statsModal'),
  blurOverlay: document.getElementById('blurOverlay'),
  closeBtn: document.getElementById('closeBtn'),
  chartImages: document.querySelectorAll('.chart-img'),
  chartButtons: document.querySelectorAll('.chart-btn'),
  scrollCharts: document.getElementById('scrollCharts')
};

function scrollLeft() {
  if (window.innerWidth > 768) {
    el.scrollCharts.scrollBy({ left: -200, behavior: 'smooth' });
  }
}

function scrollRight() {
  if (window.innerWidth > 768) {
    el.scrollCharts.scrollBy({ left: 200, behavior: 'smooth' });
  }
}

const themes = ['light', 'dark', 'ocean', 'purple', 'gradient', 'transparent'];
const themeNames = ['Light', 'Dark', 'Ocean', 'Purple', 'Gradient', 'Glass'];
let currentTheme = localStorage.getItem('selectedTheme') || 'light';

function applyTheme() {
  document.documentElement.setAttribute('data-theme', currentTheme);
  const index = themes.indexOf(currentTheme);
  el.themeText.textContent = themeNames[index];
  localStorage.setItem('selectedTheme', currentTheme);
}

function toggleTheme() {
  const index = themes.indexOf(currentTheme);
  currentTheme = themes[(index + 1) % themes.length];
  applyTheme();
}

const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

function updateDateTime() {
  const now = new Date();
  const pad = n => n.toString().padStart(2, '0');
  el.currentTime.textContent = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  el.currentDate.textContent = `${pad(now.getDate())}/${pad(now.getMonth() + 1)}/${now.getFullYear()}`;
  el.currentDay.textContent = days[now.getDay()];
}

let isModalOpen = false;

function showModal() {
  isModalOpen = true;
  el.blurOverlay.classList.add('active');
  document.body.classList.add('stats-open');
  el.statsModal.classList.add('show');
  el.statsBtn.classList.add('active');
  document.body.style.overflow = 'hidden';
  localStorage.setItem('statsVisible', 'true');
}

function hideModal() {
  isModalOpen = false;
  el.blurOverlay.classList.remove('active');
  document.body.classList.remove('stats-open');
  el.statsModal.classList.remove('show');
  el.statsBtn.classList.remove('active');
  document.body.style.overflow = '';
  localStorage.setItem('statsVisible', 'false');
}

function toggleModal() {
  isModalOpen ? hideModal() : showModal();
}

let currentChart = 'summary';
let imageLoadTimeout;

function forceImageReload(img) {
  if (imageLoadTimeout) clearTimeout(imageLoadTimeout);
  
  const timestamp = Date.now();
  const baseUrl = img.src.split('?')[0];
  const newUrl = `${baseUrl}?t=${timestamp}&cache=${Math.random()}`;
  
  img.style.display = 'none';
  img.src = '';
  
  if (img.complete) {
    img.removeAttribute('src');
    img.src = newUrl;
  } else {
    img.src = newUrl;
  }
  
  return new Promise((resolve) => {
    const handleLoad = () => {
      img.removeEventListener('load', handleLoad);
      img.removeEventListener('error', handleLoad);
      resolve();
    };
    
    img.addEventListener('load', handleLoad);
    img.addEventListener('error', handleLoad);
    
    imageLoadTimeout = setTimeout(handleLoad, 3000);
  });
}

function showChart(type) {
  if (type === currentChart) return;
  
  const newImg = document.getElementById(type);
  if (!newImg) return;
  
  el.imageContainer.classList.add('loading');
  
  const currentImg = document.getElementById(currentChart);
  if (currentImg) {
    currentImg.style.display = 'none';
  }
  
  forceImageReload(newImg).then(() => {
    setTimeout(() => {
      newImg.style.display = 'block';
      el.imageContainer.classList.remove('loading');
      currentChart = type;
    }, 300);
  });
}

function refreshAllCharts() {
  el.chartImages.forEach((img, index) => {
    setTimeout(() => {
      forceImageReload(img);
    }, index * 200);
  });
  
  showToast('success', 'Charts refreshed successfully');
}

setInterval(refreshAllCharts, 300000);

let toastTimeout;

function showToast(type, message) {
  if (toastTimeout) clearTimeout(toastTimeout);
  el.toast.className = `toast ${type}`;
  el.toastMsg.textContent = message;
  el.toast.classList.add('show');
  toastTimeout = setTimeout(() => el.toast.classList.remove('show'), 3000);
}

async function resetDatabase() {
  if (el.resetBtn.classList.contains('loading')) return;
  
  el.resetBtn.classList.add('loading');
  el.imageContainer.classList.add('loading');
  
  try {
    const response = await fetch('/cgi-bin/reset-vnstat.sh', { 
      method: 'POST',
      cache: 'no-cache',
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0'
      }
    });
    
    if (response.ok) {
      showToast('success', 'Reset Database Success');
      
      setTimeout(() => {
        refreshAllCharts();
        
        el.resetBtn.classList.remove('loading');
        el.imageContainer.classList.remove('loading');
      }, 5000);
    } else {
      throw new Error('Reset failed');
    }
  } catch (error) {
    el.resetBtn.classList.remove('loading');
    el.imageContainer.classList.remove('loading');
    showToast('error', 'Reset failed. Please try again.');
    console.error('Reset error:', error);
  }
}

el.themeBtn.addEventListener('click', e => { e.preventDefault(); toggleTheme(); });
el.statsBtn.addEventListener('click', e => { e.preventDefault(); toggleModal(); });
el.resetBtn.addEventListener('click', e => { e.preventDefault(); resetDatabase(); });
el.closeBtn.addEventListener('click', e => { e.preventDefault(); hideModal(); });
el.blurOverlay.addEventListener('click', e => { if (e.target === el.blurOverlay) hideModal(); });

document.querySelector('.grid-btns').addEventListener('click', e => {
  e.preventDefault();
  const btn = e.target.closest('.chart-btn');
  if (!btn || btn.classList.contains('active')) return;
  
  el.chartButtons.forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  showChart(btn.dataset.chart);
});

document.addEventListener('keydown', e => {
  if (e.ctrlKey && e.key === 't') {
    e.preventDefault();
    toggleTheme();
  } else if (e.key === 'Escape' && isModalOpen) {
    hideModal();
  } else if (e.key === 'ArrowLeft' && !isModalOpen) {
    e.preventDefault();
    scrollLeft();
  } else if (e.key === 'ArrowRight' && !isModalOpen) {
    e.preventDefault();
    scrollRight();
  } else if (e.key === 'F5' || (e.ctrlKey && e.key === 'r')) {
    e.preventDefault();
    refreshAllCharts();
  }
});

el.scrollCharts.addEventListener('wheel', e => {
  if (window.innerWidth > 768 && Math.abs(e.deltaY) > Math.abs(e.deltaX)) {
    e.preventDefault();
    el.scrollCharts.scrollBy({ left: e.deltaY > 0 ? 100 : -100, behavior: 'smooth' });
  }
});

function init() {
  applyTheme();
  updateDateTime();
  
  setInterval(updateDateTime, 1000);
  
  if (localStorage.getItem('statsVisible') === 'true') {
    setTimeout(showModal, 100);
  }
  
  setTimeout(() => {
    el.chartImages.forEach((img, index) => {
      const baseUrl = img.src.split('?')[0];
      img.src = `${baseUrl}?t=${Date.now()}&init=${index}`;
    });
  }, 1000);
  
  console.log('Network Monitor initialized');
  console.log(`Mode: ${window.innerWidth > 768 ? 'Desktop (Scrollable)' : 'Mobile (Grid)'}`);
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}