<?php

define('ROOT', realpath(__DIR__ .'/..'));

require_once ROOT .'/vendor/autoload.php';

// Set up the container
$container = new League\Container\Container;

// Set up the configuration
$container->add('config', function() {
    // todo: Cache response

    $configResource = ROOT .'/config/config.yaml';
    $configYaml = file_get_contents($configResource);

    if ($configYaml === false) {
        throw new RuntimeException('Configuration file could not be found. Make sure the file "config/config.yaml" exists.');
    }

    $config = yaml_parse($configYaml);

    if ($config === false) {
        throw new RuntimeException('The configuration file could not be parsed. Check to make sure it is a valid YAML file.');
    }

    return new SkinnyBlog\Config($config);
});

/** @var SkinnyBlog\Config $config */
$config = $container->get('config');

// Set up the application resource
$container->add('app', function() use ($config) {
    $app = new SkinnyBlog\Application([
        'mode'  => $config->get('env'),
        'debug' => false,
    ]);

    // Automatically parses POST bodies as Json
    $app->add(new Slim\Middleware\ContentTypes);

    // Set up error handling
    $app->error(function(Exception $e) use ($app) {
        $code = $e->getCode();
        if ($code < 200 || $code >= 600) {
            $code = 500;
        }

        $app->apiResponse(array(), $code, $e->getMessage() ?: 'A server error occurred.');
    });

    // Set up the 404 handler
    $app->notFound(function() use ($app) {
        $app->apiResponse(array(), 404, 'API resource not found.');
    });

    return $app;
});

// Set up Doctrine
$container->add('entityManager', function() use ($config) {
    $paths = [ROOT . '/src/SkinnyBlog/Entity'];

    $reader = new Doctrine\Common\Annotations\AnnotationReader;
    $driver = new Doctrine\ORM\Mapping\Driver\AnnotationDriver($reader, $paths);

    $doctrineConfig = Doctrine\ORM\Tools\Setup::createAnnotationMetadataConfiguration(
        $paths,
        $config->isDevelopment(),
        ROOT .'/tmp/doctrine/proxies'
    );
    $doctrineConfig->setMetadataDriverImpl($driver);
    $doctrineConfig->addEntityNamespace('Blog', 'SkinnyBlog\Entity');

    $entityManager = Doctrine\ORM\EntityManager::create([
        'driver'   => $config->get('db/driver'),
        'user'     => $config->get('db/username'),
        'password' => $config->get('db/password'),
        'dbname'   => $config->get('db/database'),
    ], $doctrineConfig);

    return $entityManager;
});

// Set up the OAuth validator
$container->add('validator', function() use ($config) {
    $validator = new SkinnyBlog\OAuth\GoogleValidator(
        $config->get('oauth/clientId'),
        $config->get('oauth/allowedUserIds')
    );

    return $validator;
});

return $container;
