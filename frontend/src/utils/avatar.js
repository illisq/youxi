export function generateTextAvatar(name, size = 60) {
  // 创建 canvas 元素
  const canvas = document.createElement('canvas');
  canvas.width = size;
  canvas.height = size;
  const context = canvas.getContext('2d');

  // 绘制圆形背景
  context.beginPath();
  context.arc(size/2, size/2, size/2, 0, Math.PI * 2);
  context.fillStyle = getRandomColor(name);
  context.fill();

  // 设置文字
  const surname = name ? name.charAt(0) : '?';
  context.font = `${size/2}px Arial`;
  context.fillStyle = 'white';
  context.textAlign = 'center';
  context.textBaseline = 'middle';
  context.fillText(surname, size/2, size/2);

  // 转换为 data URL
  return canvas.toDataURL('image/png');
}

// 根据名字生成固定的颜色
function getRandomColor(str) {
  const colors = [
    '#1abc9c', '#2ecc71', '#3498db', '#9b59b6', '#34495e',
    '#16a085', '#27ae60', '#2980b9', '#8e44ad', '#2c3e50',
    '#f1c40f', '#e67e22', '#e74c3c', '#95a5a6', '#f39c12',
    '#d35400', '#c0392b', '#7f8c8d'
  ];
  
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  
  return colors[Math.abs(hash) % colors.length];
} 