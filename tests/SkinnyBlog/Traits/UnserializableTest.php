<?php

class UnserializableTest extends PHPUnit_Framework_TestCase
{
    public function testCanBeUnserialized() {
        $data = [
            'firstName'  => 'Benjamin',
            'lastName'   => 'Linus',
            'postalCode' => '55123',
        ];
        $age = 44;

        $person = new UnserializablePerson($age);
        $person->unserialize($data);

        $this->assertEquals($data['firstName'], $person->getFirstName());
        $this->assertEquals($data['lastName'], $person->getLastName());
        $this->assertEquals($age, $person->getAge()); // Ensure the age isn't destroyed
        $this->assertEquals($data['postalCode'], $person->getPostalCode());
    }

    /**
     * @expectedException        InvalidArgumentException
     * @expectedExceptionMessage UnserializablePerson::$favoriteFood is not a valid property.
     */
    public function testCatchesInvalidProperty() {
        $data = [
            'favoriteFood' => 'Chorizo con huevos',
        ];

        $person = new UnserializablePerson;
        $person->unserialize($data);
    }

    /**
     * @expectedException        InvalidArgumentException
     * @expectedExceptionMessage UnserializablePerson::$age is a protected property.
     */
    public function testCatchesProtectedProperty() {
        $data = [
            'age' => 999,
        ];

        $person = new UnserializablePerson;
        $person->unserialize($data);
    }

    public function testIgnoresProtectedProperty() {
        $data = [
            'age' => 999,
        ];

        $age = 24;
        $person = new UnserializablePerson($age);
        $person->unserialize($data, false);

        $this->assertEquals($age, $person->getAge());
    }

    public function testUsesSetter() {
        $data = [
            'state' => 'minnesota',
        ];

        $person = new UnserializablePerson;
        $person->unserialize($data);

        $this->assertEquals(ucfirst($data['state']), $person->getState());
    }
}

class UnserializablePerson
{
    use SkinnyBlog\Traits\Unserializable;

    protected $firstName;
    protected $lastName;
    protected $age;
    protected $postalCode;
    protected $state;

    /**
     * @param int $age
     */
    public function __construct($age = 18) {
        $this->age = $age;
    }

    /**
     * @return string
     */
    public function getFirstName()
    {
        return $this->firstName;
    }

    /**
     * @return string
     */
    public function getLastName()
    {
        return $this->lastName;
    }

    /**
     * @return int
     */
    public function getAge()
    {
        return $this->age;
    }

    /**
     * @return string
     */
    public function getPostalCode()
    {
        return $this->postalCode;
    }

    /**
     * @param mixed $state
     */
    public function setState($state)
    {
        $this->state = ucfirst($state);
    }

    /**
     * @return mixed
     */
    public function getState()
    {
        return $this->state;
    }

    /**
     * @return array Returns a list of values protected from being injected
     */
    public function getProtectedProperties() {
        return [
            'age',
        ];
    }
}