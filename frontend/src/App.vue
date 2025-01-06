<template>
  <div id="app">
    <nav>
      <router-link to="/">首页</router-link>
    </nav>
    <router-view/>
  </div>
</template>

<style>
body {
  margin: 0;
  font-family: Arial, sans-serif;
  background: #000000;
  color: #e0e0e0;
}

#app {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #e0e0e0;
}

nav {
  padding: 16px;
  background: #121212;
  box-shadow: 0 2px 4px rgba(0,0,0,0.3);
}

nav a {
  color: #e0e0e0;
  text-decoration: none;
  font-weight: bold;
}

nav a.router-link-active {
  color: #f4f4f4;
}
</style> 