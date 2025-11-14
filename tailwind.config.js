const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/components/**/*.{erb,html,rb}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['InterVariable', ...defaultTheme.fontFamily.sans],
      },
      colors: {
        'nintendo-red': {
          DEFAULT: '#E60012',
          50: '#FFE5E7',
          100: '#FFCCCF',
          200: '#FF999F',
          300: '#FF666F',
          400: '#FF333F',
          500: '#E60012',
          600: '#CC0010',
          700: '#B3000E',
          800: '#99000C',
          900: '#80000A',
        },
      },
    },
  },
  plugins: [],
}
