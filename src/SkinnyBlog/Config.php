<?php

namespace SkinnyBlog;

use ArrayAccess;
use BadMethodCallException;
use InvalidArgumentException;

class Config implements ArrayAccess
{
    /**
     * @var string The value denoting that an option must be required
     */
    static $REQUIRED = '__required__';

    /**
     * @var array
     */
    protected $data;

    /**
     * @param array $config
     */
    public function __construct($config) {
        $defaults = $this->getDefaultConfiguration();
        $this->data = $this->recursiveMerge($config, $defaults);
    }

    /**
     * Merges two configuration arrays using values from the
     * left before values on the right. If values on the right
     * are required but not filled, an exception will be thrown.
     *
     * @param array $left
     * @param array $right
     * @param array $path
     *
     * @return array
     */
    protected function recursiveMerge($left, $right, $path = []) {
        if (!is_array($left)) {
            throw new InvalidArgumentException('$left must be an array, got "'. gettype($left) .'" instead.');
        }
        if (!is_array($right)) {
            throw new InvalidArgumentException('$right must be an array, got "'. gettype($right) .'" instead.');
        }

        foreach ($right as $key => $value) {
            $breadcrumbs = array_merge($path, [$key]);

            if (array_key_exists($key, $left)) {
                if (is_array($value)) {
                    if (!is_array($left[$key])) {
                        throw new InvalidArgumentException('Config value '. $this->makeArrayPath($breadcrumbs) .' must be an array');
                    }

                    $left[$key] = $this->recursiveMerge($left[$key], $value, $breadcrumbs);
                }
            } elseif ($value === self::$REQUIRED) {
                throw new InvalidArgumentException('Config value '. $this->makeArrayPath($breadcrumbs) .' must be set');
            } elseif (is_array($value)) {
                $left[$key] = $this->recursiveMerge([], $value, $breadcrumbs);
            } else {
                $left[$key] = $value;
            }
        }

        return $left;
    }

    /**
     * Helper function for error outputs.
     *
     * @param array $path
     *
     * @return string
     */
    protected function makeArrayPath($path) {
        array_walk($path, function ($item) {
            return addcslashes($item, '"');
        });

        return '"'. implode('/', $path) .'"';
    }

    /**
     * @return array The default configuration values
     */
    public static function getDefaultConfiguration() {
        return [
            'env' => 'development',
            'db' => [
                'driver'   => 'pdo_mysql',
                'username' => self::$REQUIRED,
                'password' => self::$REQUIRED,
                'database' => self::$REQUIRED,
            ],
        ];
    }

    /**
     * @return bool Whether or not this application is in development mode
     */
    public function isDevelopment() {
        return $this->get('env') !== 'production';
    }

    /**
     * Walks through an the configuration to find a value. For example, using a key
     * of "db/username" will fetch the configuration value inf $config['db']['username'].
     *
     * @param string $key
     * @param bool   $exceptionOnFailure
     * @param bool   $default
     *
     * @return array|bool
     */
    public function get($key, $exceptionOnFailure = true, $default = false) {
        $keyPath = explode('/', $key);

        $i = 0;
        $value = $this->data;
        do {
            if (is_array($value) && array_key_exists($keyPath[$i], $value)) {
                $value = $value[$keyPath[$i]];
            } elseif ($exceptionOnFailure) {
                throw new InvalidArgumentException("The config value \"$key\" does not exist.");
            } else {
                return $default;
            }

            $i++;
        } while ($i < count($keyPath));

        return $value;
    }

    /**
     * @link http://php.net/manual/en/arrayaccess.offsetexists.php
     *
     * @param string $offset An offset to check for
     *
     * @return bool True on success or false on failure
     */
    public function offsetExists($offset)
    {
        try {
            $this->get($offset);
        } catch (InvalidArgumentException $e) {
            return false;
        }

        return true;
    }

    /**
     * @link http://php.net/manual/en/arrayaccess.offsetget.php
     *
     * @param string $offset The offset to retrieve
     *
     * @return mixed Can return all value types
     */
    public function offsetGet($offset)
    {
        return $this->get($offset);
    }

    /**
     * @link http://php.net/manual/en/arrayaccess.offsetset.php
     *
     * @param string $offset The offset to assign the value to.
     * @param mixed  $value  The value to set.
     *
     * @return void
     *
     * @throws BadMethodCallException This method is not implemented
     */
    public function offsetSet($offset, $value)
    {
        throw new BadMethodCallException('This method is not implemented');
    }

    /**
     * @link http://php.net/manual/en/arrayaccess.offsetunset.php
     *
     * @param string $offset The offset to unset.
     *
     * @return void
     *
     * @throws BadMethodCallException This method is not implemented
     */
    public function offsetUnset($offset)
    {
        throw new BadMethodCallException('This method is not implemented');
    }
}