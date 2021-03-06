<?php

namespace SkinnyBlog;

use Doctrine\ORM\EntityManager;
use InvalidArgumentException;
use SkinnyBlog\Entity\Article;
use SkinnyBlog\Entity\Tag;
use SkinnyBlog\OAuth\Validator;
use Slim\Slim;

class Application extends Slim
{
    /**
     * @param array  $data
     * @param int    $code
     * @param string $message
     * @param array  $additionalMeta
     */
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
     * @param Validator $oauth
     *
     * @return bool Whether or not the requester has a valid auth token
     */
    public function hasAuthorization(Validator $oauth) {
        $token = $this->request->headers->get('X-OAuth-Token');

        if (!$oauth->isAuthorizedToken($token)) {
            $this->apiResponse([], 401, 'Invalid OAuth token');
            return false;
        } else {
            return true;
        }
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
            $this->apiResponse([], 404, "Article id:$id not found");
            return null;
        }
    }

    /**
     * @param EntityManager $em
     * @param int           $id
     *
     * @return Tag|null The matching tag if it exists
     */
    public function getTag(EntityManager $em, $id) {
        /** @var Article $article */
        $tag = $em->find('Blog:Tag', $id);

        if ($tag) {
            return $tag;
        } else {
            $this->apiResponse([], 404, "Tag id:$id not found");
            return null;
        }
    }

    /**
     * @param EntityManager $em   The entity manager
     * @param array         $tags The tags to unserialize
     *
     * @return array The unserialized tags
     */
    public function unserializeTags(EntityManager $em, $tags) {
        return array_map(function ($tag) use ($em) {
            // If this is an ID, grab the reference entity
            if (array_key_exists('id', $tag)) {
                return $em->getReference('Blog:Tag', $tag['id']);
            } elseif (array_key_exists('name', $tag)) {
                // Look up the tag
                $entity = $em->getRepository('Blog:Tag')->findOneByName($tag['name']);

                // Otherwise create a new tag
                if (!$entity) {
                    $entity = new Entity\Tag([
                        'name' => $tag['name'],
                    ]);

                    $em->persist($entity);
                }

                return $entity;
            } else {
                throw new InvalidArgumentException('A tag must have an ID or a name.');
            }
        }, $tags);
    }
}