module.exports = {
    apps : [{
      name: 'k1',
      script: '/usr/src/app/bundle/main.js',
      args: '',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      output: './out.log',
        error: './error.log',
          log: './combined.outerr.log',
      env: {
        NODE_ENV:"production",
        PORT:"3400"
      },
      env_production: {
        NODE_ENV:"production",
        PORT:"3400"
      }
    }],
  
    deploy : {
      
    }
  }
  