# Skinny Blog

This is a rather simple RESTful API-based blog that uses [AngularJS] to
render articles served by a [Slim Framework] server.

## Setting Up for Development

Start by running composer:

```
$ composer install
```

Copy the `/config/config.yaml.dist` file to `/config/config.yaml` and change the
file as necessary. After doing that, tell Doctrine to generate the necessary
schema to run the blog:

```
$ ./vendor/bin/doctrine orm:schema-tool:create
```

We can have PHP server the site for us (it will set up all of the proper re-write rules):

```
$ cd public/
$ php -S localhost:8080
```

If you want to work on the frontend, you'll want to install [Gulp] to transpile
the Sass and CoffeeScript files in addition to all of the Gulp packages denoted
in the `package.json` file:

```
$ npm install -g gulp coffee-script
...
$ npm install
```

For simplicity reasons, the minified files are committed to the code base to prevent
having to install Node and all of its dependencies on the production server. The
map files are ignore by the `.gitignore` file, but you can also run the `build` or
`default` Gulp tasks to remove the map files.

## Notes

This platform is still in heavy development and really isn't designed to be installed
and used by everyone. This project is mostly for my personal blog, but there's no
reason to close-source the codebase.

AngularJS: https://angularjs.org/
Slim Framework: http://www.slimframework.com/
Doctrine: http://www.doctrine-project.org/
Gulp: http://gulpjs.com/