module.exports = {
    apps: [{
        name: 'KIMain',
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
    }, {
        name: 'Python',
        script: '/usr/src/tempapp/python/index.py',
        args: '',
        instances: 1,
        "exec_interpreter": "python",
        autorestart: true,
        watch: false,
        max_memory_restart: '1G',
        output: './outpython.log',
        error: './errorpython.log',
        log: './combinedpython.outerr.log'
    }, {
        name: 'Perl',
        script: '/usr/src/tempapp/crawler/dataService.pl',
        args: 'daemon -l http://*:3030',
        instances: 1,
        "exec_interpreter": "perl",
        autorestart: true,
        watch: false,
        max_memory_restart: '1G',
        output: './outperl.log',
        error: './errorperl.log',
        log: './combinedperl.outerr.log'
    }],

    deploy: {

    }
}