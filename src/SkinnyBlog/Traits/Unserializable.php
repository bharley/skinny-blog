<?php

namespace SkinnyBlog\Traits;

use InvalidArgumentException;

trait Unserializable {
    /**
     * @param array $data                 The data to unserialize into the given object
     * @param bool  $exceptionOnProtected Whether or not we should throw an exception if a protected property is trying to be set
     */
    public function unserialize($data, $exceptionOnProtected = true) {
        if (!is_array($data)) {
            throw new InvalidArgumentException('Data to unserialize must be an array.');
        }

        $protectedProperties = $this->getProtectedProperties();
        foreach ($data as $property => $value) {
            $method = 'set'. ucfirst($property);

            // Try to use a setter if possible
            if (method_exists(__CLASS__, $method)) {
                $this->$method($value);
            } elseif (in_array($property, $protectedProperties)) {
                if ($exceptionOnProtected) {
                    throw new InvalidArgumentException(__CLASS__ .'::$'. $property .' is a protected property.');
                }
            } elseif (property_exists(__CLASS__, $property)) {
                $this->$property = $value;
            } else {
                throw new InvalidArgumentException(__CLASS__ .'::$'. $property .' is not a valid property.');
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