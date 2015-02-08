<?php

namespace SkinnyBlog\Traits;

use InvalidArgumentException;

trait Unserializable {
    /**
     * @param array $data The data to unserialize into the given object
     */
    public function unserialize($data) {
        if (!is_array($data)) {
            throw new InvalidArgumentException('Data to unserialize must be an array.');
        }

        $protectedProperties = $this->getProtectedProperties();
        foreach ($data as $property => $value) {
            if (!property_exists(__CLASS__, $property)) {
                throw new InvalidArgumentException(__CLASS__ .'::$'. $property .' is not a valid property.');
            } elseif (in_array($property, $protectedProperties)) {
                throw new InvalidArgumentException(__CLASS__ .'::$'. $property .' is a protected property.');
            }

            // Try to use a setter if possible
            $method = 'set'. ucfirst($property);
            if (method_exists(__CLASS__, $method)) {
                $this->$method($value);
            } else {
                $this->$property = $value;
            }
        }
    }

    /**
     * @return array Returns a list of values protected from being injected
     */
    public function getProtectedProperties() {
        return [];
    }
}