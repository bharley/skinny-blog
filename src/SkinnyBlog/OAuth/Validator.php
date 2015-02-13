<?php

namespace SkinnyBlog\OAuth;


abstract class Validator
{
    /**
     * @var string
     */
    protected $clientId;

    /**
     * @var array
     */
    protected $allowedUserIds;

    /**
     * @param string $clientId       The client ID of the application
     * @param array  $allowedUserIds The users allowed into our app
     */
    public function __construct($clientId, $allowedUserIds) {
        $this->clientId = $clientId;
        $this->allowedUserIds = $allowedUserIds;
    }

    /**
     * @param string $token The token to check
     *
     * @return bool Whether or not these credentials are valid for this application
     */
    public function isAuthorizedToken($token) {
        // todo: Cache this response
        $userId = $this->getUserId($token);

        return $this->isAllowedUser($userId);
    }

    /**
     * @param string $token The token for the client in question
     *
     * @return string|bool The user ID or false if the token is invalid
     */
    abstract protected function getUserId($token);

    /**
     * @param string $userId The client ID to look up
     *
     * @return bool Whether or not this client is allowed
     */
    protected function isAllowedUser($userId) {
        return in_array($userId, $this->allowedUserIds);
    }

    /**
     * @return string
     */
    public function getClientId() {
        return $this->clientId;
    }
}