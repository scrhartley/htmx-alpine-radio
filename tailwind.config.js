/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/main/resources/templates/**/*.ftlh"],
  theme: {
    extend: {},
  },
  plugins: [],
  experimental: {
    optimizeUniversalDefaults: true, // Reduce output size
  },
  future: {
    disableColorOpacityUtilitiesByDefault:true // Reduce output size
  },
}

