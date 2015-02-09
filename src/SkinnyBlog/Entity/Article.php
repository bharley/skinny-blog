<?php

namespace SkinnyBlog\Entity;

use DateTime;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use InvalidArgumentException;
use JsonSerializable;
use SkinnyBlog\Traits\Unserializable;

/**
 * @ORM\Entity
 * @ORM\Table(
 *     uniqueConstraints={@ORM\UniqueConstraint(columns={"slug"})}
 * )
 */
class Article implements JsonSerializable
{
    use Unserializable;

    /**
     * @var int
     * @ORM\Id
     * @ORM\GeneratedValue
     * @ORM\Column(type="integer")
     */
    protected $id;

    /**
     * @var string
     * @ORM\Column(type="string")
     */
    protected $slug;

    /**
     * @var string
     * @ORM\Column(type="string")
     */
    protected $title;

    /**
     * @var string
     * @ORM\Column(type="text")
     */
    protected $text;

    /**
     * @var bool
     * @ORM\Column(type="boolean")
     */
    protected $published;

    /**
     * @var DateTime
     * @ORM\Column(type="datetime")
     */
    protected $publishedDate;

    /**
     * @var Collection
     * @ORM\ManyToMany(targetEntity="Tag", inversedBy="articles")
     */
    protected $tags;

    /**
     * @param array $data Data to unserialize this instance with (Optional)
     */
    public function __construct($data = null) {
        $this->published = false;
        $this->publishedDate = new DateTime;
        $this->tags = new ArrayCollection;

        if ($data) {
            $this->unserialize($data);
        }
    }

    /**
     * @param bool $published Whether or not this article has been published
     */
    public function setPublished($published = true) {
        $this->published = $published;
    }

    /**
     * Ensures that the article slug is valid.
     *
     * @param string $slug
     */
    public function setSlug($slug) {
        if (!preg_match('#^\d{4}/\d{2}/[a-z0-9-]+$#i', $slug)) {
            throw new InvalidArgumentException('Article slug must be in the format "YYYY/MM/title" where the title may only contain the characters A-Z, 0-9 and dash ("-").');
        }

        $this->slug = $slug;
    }

    /**
     * @return array The parts of the slug
     */
    public function getSlugParts() {
        list($year, $month, $title) = explode('/', $this->slug);

        return compact('year', 'month', 'title');
    }

    public function setPublishedDate($date) {
        if (!$date instanceof DateTime) {
            $date = new DateTime($date);
        }

        $this->publishedDate = $date;
    }

    /**
     * @param array $tags
     */
    public function setTags($tags) {
        $this->tags = new ArrayCollection($tags);
    }

    /**
     * @return array
     */
    public function getTags() {
        return $this->tags->map(function (Tag $tag) {
            return $tag->jsonSerialize();
        })->toArray();
    }

    /**
     * @return array The properties that are not allowed to be injected by unserialization
     */
    public function getProtectedProperties() {
        return [
            'id',
        ];
    }

    /**
     * @link http://php.net/manual/en/jsonserializable.jsonserialize.php
     *
     * @return array Data which can be serialized by json_encode, which is a value of any type other than a resource.
     */
    public function jsonSerialize()
    {
        return [
            'id'            => $this->id,
            'slug'          => $this->slug,
            'slugParts'     => $this->getSlugParts(),
            'title'         => $this->title,
            'text'          => $this->text,
            'published'     => $this->published,
            'publishedDate' => $this->publishedDate ? $this->publishedDate->format('c') : null,
            'tags'          => $this->getTags(),
        ];
    }
}