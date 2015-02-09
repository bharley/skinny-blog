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
    $tag = $app->request->get('tag');

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
                    ->setMaxResults($page * $pageSize);
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

    $app->apiResponse([
        'articles' => $articles,
    ], 200, null, $pages !== false ? ['pages' => $pages] : []);
});

// Save a new article
$app->post('/articles', function() use ($app, $em) {
    $data = $app->request->getBody();

    if (is_array($data) && array_key_exists('article', $data)) {
        $data = $data['article'];

        // Find tags and deal with them
        if (array_key_exists('tags', $data)) {
            $data['tags'] = array_map(function ($id) use ($em) {
                return $em->getReference('Blog:Tag', $id);
            }, $data['tags']);
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
$app->get('/articles/:id', function ($id) use ($app, $em) {
    $article = $app->getArticle($em, $id);

    if ($article) {
        $app->apiResponse([
            'article' => $article,
        ]);
    }
});

// Get a single article by it's slug
$app->get('/articles/:year/:month/:title', function ($year, $month, $title) use ($app, $em) {
    $dql = 'SELECT a FROM Blog:Article a WHERE a.slug = :slug';
    $article = $em->createQuery($dql)
                  ->setParameter('slug', "$year/$month/$title")
                  ->getOneOrNullResult();

    if ($article) {
        $app->apiResponse([
            'article' => $article,
        ]);
    } else {
        $app->apiResponse([], 404, "Article year:$year, month:$month, title:\"$title\" not found");
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

        if (is_array($data) && array_key_exists('article', $data)) {
            $data = $data['article'];

            // Find tags and deal with them
            if (array_key_exists('tags', $data)) {
                $data['tags'] = array_map(function ($id) use ($em) {
                    return $em->getReference('Blog:Tag', $id);
                }, $data['tags']);
            }

            $article->unserialize($data);
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
$app->delete('/articles/:id', function ($id) use ($app, $em) {
    $article = $app->getArticle($em, $id);

    if ($article) {
        $em->remove($article);
        $em->flush();

        $app->apiResponse([], 200, "Article id:$id deleted");
    }
});

// Get all tags
$app->get('/tags', function () use ($app, $em) {
    $app->apiResponse([
        'tags' => $em->getRepository('Blog:Tag')->findAll(),
    ]);
});

// Save a new tag
$app->post('/tags', function() use ($app, $em) {
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
$app->delete('/tags/:id', function ($id) use ($app, $em) {
    $tag = $app->getTag($em, $id);

    if ($tag) {
        $em->remove($tag);
        $em->flush();

        $app->apiResponse([], 200, "Tag id:$id deleted");
    }
});

$app->run();
