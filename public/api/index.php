<?php

/** @var League\Container\Container $container */
$container = require '../../src/bootstrap.php';

/** @var SkinnyBlog\Application $app */
$app = $container->get('app');
/** @var Doctrine\ORM\EntityManager $em */
$em = $container->get('entityManager');

// Get all articles
$app->get('/articles', function () use ($app, $em) {
    $pageSize = $app->request->get('paginate', 10);
    $page = $app->request->get('page');
    $pages = false;

    $dql = 'SELECT a FROM Blog:Article a WHERE a.published = true ORDER BY a.publishedDate DESC';
    if ($page !== null) {
        if ($page <= 0) {
            $page = 1;
        }

        $query = $em->createQuery($dql)
                    ->setFirstResult(($page - 1) * $pageSize)
                    ->setMaxResults($page * $pageSize);
        $paginator = new Doctrine\ORM\Tools\Pagination\Paginator($query, false);

        $pages = ceil(count($paginator) / $pageSize);

        $articles = [];
        foreach ($paginator as $article) {
            /** @var SkinnyBlog\Entity\Article $article */
            $articles[] = $article;
        }
    } else {
        $articles = $em->createQuery($dql)->getArrayResult();
    }

    $app->apiResponse([
        'articles' => $articles,
    ], 200, null, $pages !== false ? ['pages' => $pages] : []);
});

// Save a new article
$app->post('/articles', function() use ($app, $em) {
    $data = $app->request->getBody();

    $article = new SkinnyBlog\Entity\Article($data);
    $em->persist($article);
    $em->flush();

    $app->apiResponse([
        'article' => $article,
    ]);
});

// Get a single article
$app->get('/articles/:id', function ($id) use ($app, $em) {
    $article = $app->getArticle($em, $id);

    if ($article) {
        $app->apiResponse([
            'article' => $article,
        ]);
    }
});

// Publish an article
$app->put('/articles/:id/publish', function ($id) use ($app, $em) {
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
$app->put('/articles/:id/unpublish', function ($id) use ($app, $em) {
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
$app->put('/articles/:id', function ($id) use ($app, $em) {
    $article = $app->getArticle($em, $id);

    if ($article) {
        $data = $app->request->getBody();
        $article->unserialize($data);
        $em->flush();

        $app->apiResponse([
            'article' => $article,
        ]);
    }
});

// Delete an article
$app->delete('/articles/:id', function ($id) use ($app, $em) {
    $article = $app->getArticle($em, $id);

    if ($article) {
        $em->remove($article);
        $em->flush();

        $app->apiResponse([], 200, "Article id:$id deleted");
    }
});


$app->run();
