<?php

// This file tells Doctrine's command line tool about our application

use Doctrine\ORM\Tools\Console\ConsoleRunner;

$container = require_once 'src/bootstrap.php';

return ConsoleRunner::createHelperSet($container->get('entityManager'));
