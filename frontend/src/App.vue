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
  background: #f5f5f5;
}

#app {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
}

nav {
  padding: 16px;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

nav a {
  color: #2c3e50;
  text-decoration: none;
  font-weight: bold;
}

nav a.router-link-active {
  color: #42b983;
}
</style> 