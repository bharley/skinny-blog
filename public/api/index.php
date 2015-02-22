<?php

/** @var League\Container\Container $container */
$container = require '../../src/bootstrap.php';

/** @var SkinnyBlog\Application $app */
$app = $container->get('app');
/** @var Doctrine\ORM\EntityManager $em */
$em = $container->get('entityManager');
/** @var SkinnyBlog\OAuth\Validator $oauth */
$oauth = $container->get('validator');

// Get all articles
$app->get('/articles', function () use ($app, $container) {
    $pageSize = $app->request->get('paginate', 10);
    $page = $app->request->get('page');
    $pages = false;
    $tag = $app->request->get('tag');

    /** @var Doctrine\ORM\EntityManager $em */
    $em = $container->get('entityManager');

    $qb = $em->createQueryBuilder()
             ->select('a', 't')
             ->from('Blog:Article', 'a')
             ->leftJoin('a.tags', 't')
             ->where('a.published = true')
             ->orderBy('a.publishedDate', 'DESC');

    if ($tag) {
        $qb->andWhere('a.id IN (SELECT a2.id FROM Blog:Tag t2 LEFT JOIN t2.articles a2 WHERE t2.name = :name)')
           ->setParameter('name', str_replace('-', ' ', $tag));
    }

    if ($page !== null) {
        if ($page <= 0) {
            $page = 1;
        }

        $query = $qb->getQuery()
                    ->setFirstResult(($page - 1) * $pageSize)
                    ->setMaxResults($pageSize);
        $paginator = new Doctrine\ORM\Tools\Pagination\Paginator($query, true);

        $pages = ceil(count($paginator) / $pageSize);

        $articles = [];
        foreach ($paginator as $article) {
            /** @var SkinnyBlog\Entity\Article $article */
            $articles[] = $article;
        }
    } else {
        $articles = $qb->getQuery()->getResult();
    }

    // Add the markdown parser
    /** @var Parsedown $parser */
    $parser = $container->get('markdown');
    foreach ($articles as $article) {
        $article->setParser($parser);
    }

    $app->apiResponse([
        'articles' => $articles,
    ], 200, null, $pages !== false ? ['pages' => $pages] : []);
});

// Get all articles -- admin fetch that includes unpublished
$app->get('/articles/all', function () use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $articles = $em->createQueryBuilder()
                   ->select('a', 't')
                   ->from('Blog:Article', 'a')
                   ->leftJoin('a.tags', 't')
                   ->orderBy('a.publishedDate', 'DESC')
                   ->getQuery()
                   ->useResultCache(false)
                   ->getResult();

    $app->apiResponse([
        'articles' => $articles,
    ]);
});

// Save a new article
$app->post('/articles', function() use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $data = $app->request->getBody();

    if (is_array($data) && array_key_exists('article', $data)) {
        $data = $data['article'];

        // Find tags and deal with them
        if (array_key_exists('tags', $data)) {
            $data['tags'] = $app->unserializeTags($em, $data['tags']);
        }

        $article = new SkinnyBlog\Entity\Article($data);
        $em->persist($article);
        $em->flush();

        $app->apiResponse([
            'article' => $article,
        ]);
    } else {
        $app->apiResponse([], 400, 'Missing hash "article" in request.');
    }
});

// Get a single article
$app->get('/articles/:id', function ($id) use ($app, $em, $oauth) {
    $article = $app->getArticle($em, $id);

    if ($article) {
        $app->apiResponse([
            'article' => $article,
        ]);
    }
});

// Get a single article by it's slug
$app->get('/articles/:year/:month/:title', function ($year, $month, $title) use ($app, $container) {
    /** @var Doctrine\ORM\EntityManager $em */
    $em = $container->get('entityManager');

    $dql = 'SELECT a FROM Blog:Article a WHERE a.slug = :slug';
    $article = $em->createQuery($dql)
                  ->setParameter('slug', "$year/$month/$title")
                  ->getOneOrNullResult();

    if ($article) {
        /** @var Parsedown $parser */
        $parser = $container->get('markdown');
        $article->setParser($parser);

        $app->apiResponse([
            'article' => $article,
        ]);
    } else {
        $app->apiResponse([], 404, "Article year:$year, month:$month, title:\"$title\" not found");
    }
});

// Publish an article
$app->put('/articles/:id/publish', function ($id) use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $article = $app->getArticle($em, $id);

    if ($article) {
        $article->setPublished();
        $em->flush();

        $app->apiResponse([
            'article' => $article,
        ]);
    }
});

// Unpublish an article
$app->put('/articles/:id/unpublish', function ($id) use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $article = $app->getArticle($em, $id);

    if ($article) {
        $article->setPublished(false);
        $em->flush();

        $app->apiResponse([
            'article' => $article,
        ]);
    }
});

// Update an article
$app->put('/articles/:id', function ($id) use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $article = $app->getArticle($em, $id);

    if ($article) {
        $data = $app->request->getBody();

        if (is_array($data) && array_key_exists('article', $data)) {
            $data = $data['article'];

            // Find tags and deal with them
            if (array_key_exists('tags', $data)) {
                $data['tags'] = $app->unserializeTags($em, $data['tags']);
            }

            $article->unserialize($data, false);
            $em->flush();

            $app->apiResponse([
                'article' => $article,
            ]);
        } else {
            $app->apiResponse([], 400, 'Missing hash "article" in request.');
        }
    }
});

// Delete an article
$app->delete('/articles/:id', function ($id) use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $article = $app->getArticle($em, $id);

    if ($article) {
        $em->remove($article);
        $em->flush();

        $app->apiResponse([], 200, "Article id:$id deleted");
    }
});

// Get all tags
$app->get('/tags', function () use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $app->apiResponse([
        'tags' => $em->getRepository('Blog:Tag')->findAll(),
    ]);
});

// Save a new tag
$app->post('/tags', function() use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $data = $app->request->getBody();

    if (is_array($data) && array_key_exists('tag', $data)) {
        $data = $data['tag'];

        $tag = new SkinnyBlog\Entity\Tag($data);
        $em->persist($tag);
        $em->flush();

        $app->apiResponse([
            'tag' => $tag,
        ]);
    } else {
        $app->apiResponse([], 400, 'Missing hash "tag" in request.');
    }
});

// Delete a tag
$app->delete('/tags/:id', function ($id) use ($app, $em, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $tag = $app->getTag($em, $id);

    if ($tag) {
        $em->remove($tag);
        $em->flush();

        $app->apiResponse([], 200, "Tag id:$id deleted");
    }
});

// Upload an image
$app->post('/images', function() use ($app, $oauth) {
    if (!$app->hasAuthorization($oauth)) return;

    $file = $_FILES['file'];

    // Check for file upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $app->apiResponse([], 400, "File could not be uploaded (errorno: {$file['error']}");
    }

    // Set up the file path
    $destination = [
        'path'      => '/assets/img/' . date('Y/m') . '/',
        'name'      => bin2hex(openssl_random_pseudo_bytes(24)),
        'extension' => '.' . pathinfo($file['name'], PATHINFO_EXTENSION),
    ];
    $destination['directory'] = ROOT .'/public/'. $destination['path'];

    // Make sure the upload location exists
    if (!is_dir($destination['directory']) && !mkdir($destination['directory'], 0777, true)) {
        $app->apiResponse([], 500, 'Could not create upload directory. Check upload directory permissions.');
    }

    // Construct the final path
    $path = join('', [
        $destination['path'],
        $destination['name'],
        $destination['extension'],
    ]);
    $destination = join('', [
        $destination['directory'],
        $destination['name'],
        $destination['extension'],
    ]);

    // Try to upload the image
    if (move_uploaded_file($file['tmp_name'], $destination)) {
        $app->apiResponse([
            'image' => $path,
        ]);
    } else {
        $app->apiResponse([], 500, 'File could not be moved. Check upload directory permissions.');
    }
});

// Returns information needed to perform an OAuth request against Google
$app->get('/auth/info', function() use ($app, $oauth) {
    $app->apiResponse([
        'clientId' => $oauth->getClientId(),
    ]);
});

// Check authentication headers for validity
$app->get('/auth/check', function () use ($app, $oauth) {
    if ($app->hasAuthorization($oauth)) {
        $app->apiResponse([], 200, 'OAuth token is valid');
    }
});

$app->run();
