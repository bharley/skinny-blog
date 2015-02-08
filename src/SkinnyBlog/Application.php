<?php

namespace SkinnyBlog;

use Doctrine\ORM\EntityManager;
use SkinnyBlog\Entity\Article;
use Slim\Slim;

class Application extends Slim
{
    public function apiResponse(array $data, $code = 200, $message = null, $additionalMeta = []) {
        // Attach metadata
        $data['meta'] = array_merge([
            'status_code' => $code,
        ], $additionalMeta);

        if ($message !== null) {
            $data['meta']['message'] = $message;
        }

        // Build the response
        $response = $this->response();
        $response['Content-Type'] = 'application/json';
        $response->setStatus($code);
        $response->body(json_encode($data));
    }

    /**
     * @param EntityManager $em
     * @param int           $id
     *
     * @return Article|null The matching article if it exists
     */
    public function getArticle(EntityManager $em, $id) {
        /** @var Article $article */
        $article = $em->find('Blog:Article', $id);

        if ($article) {
            return $article;
        } else {
            $this->apiResponse([], 400, "Article id:$id not found");
            return null;
        }
    }
}