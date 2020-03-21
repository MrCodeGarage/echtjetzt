module.exports = {
    apps: [{
        name: 'KI',
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
            MONGO_URL: "mongodb+srv://hackaton:R8kiR0e3XhIqaVqp@cluster0.yiba8.mongodb.net/ki?retryWrites=true&w=majority",
            ROOT_URL: "http://echtjetzt.code-garage-solutions.de",
            NODE_ENV: "production",
            PORT: "3400"
        },
        env_production: {
            NODE_ENV: "production",
            PORT: "3400"
        }
    }],

    deploy: {

    }
}