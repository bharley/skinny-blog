<?php

class ConfigTest extends PHPUnit_Framework_TestCase
{
    public function testCanMergeConfigAndWalkPath() {
        $values = [
            'menu' => [
                'Queso' => 2.99,
            ],
            'location' => 'Marmalade Drive, Seattle, Washington',
            'specials' => [
                'Chicken mole' => 11.99,
            ],
        ];

        $config = new ConfigMock($values);

        $this->assertEquals($values['menu']['Queso'], $config->get('menu/Queso'));
        $this->assertEquals(1.99, $config['menu/Chips']);
        $this->assertEquals($values['location'], $config->get('location'));
        $this->assertEquals($values['specials']['Chicken mole'], $config->get('specials/Chicken mole'));
    }

    /**
     * @expectedException        InvalidArgumentException
     * @expectedExceptionMessage Config value "menu/Queso" must be set
     */
    public function testExceptionOnMissingRequirement() {
        $config = new ConfigMock([]);
    }

    /**
     * @expectedException        InvalidArgumentException
     * @expectedExceptionMessage Config value "menu" must be an array
     */
    public function testExceptionOnValueNotArray() {
        $config = new ConfigMock([
            'menu' => 'French onion soup',
        ]);
    }
}

class ConfigMock extends SkinnyBlog\Config
{
    /**
     * @return array
     */
    public static function getDefaultConfiguration() {
        return [
            'menu' => [
                'Chorizon con huevos' => 7.99,
                'Salsa'               => .99,
                'Chips'               => 1.99,
                'Queso'               => '__required__',
            ],
            'location' => '__required__',
            'open'     => '10:30',
            'close'    => '22:00',
        ];
    }
}