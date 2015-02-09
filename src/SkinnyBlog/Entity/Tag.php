<?php

namespace SkinnyBlog\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use JsonSerializable;
use SkinnyBlog\Traits\Unserializable;

/**
 * @ORM\Entity
 * @ORM\Table(
 *     uniqueConstraints={@ORM\UniqueConstraint(columns={"name"})}
 * )
 */
class Tag implements JsonSerializable
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
    protected $name;

    /**
     * @var Collection
     * @ORM\ManyToMany(targetEntity="Article", mappedBy="tags")
     */
    protected $articles;

    /**
     * @param array $data Data to unserialize this instance with (Optional)
     */
    public function __construct($data = null) {
        $this->articles = new ArrayCollection;

        if ($data) {
            $this->unserialize($data);
        }
    }

    public function getUrl() {
        return str_replace(' ', '-', $this->name);
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
    function jsonSerialize() {
        return [
            'id'       => $this->id,
            'name'     => $this->name,
            'url'      => $this->getUrl(),
        ];
    }
}