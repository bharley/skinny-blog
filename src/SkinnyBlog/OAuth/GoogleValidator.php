<?php

namespace SkinnyBlog\OAuth;

class GoogleValidator extends Validator
{
    /**
     * @param string $token The token for the client in question
     *
     * @return string|bool The user ID or false if the token is invalid
     */
    protected function getUserId($token)
    {
        $curl = curl_init();
        curl_setopt_array($curl, [
            CURLOPT_URL            => $this->getValidationEndpoint($token),
            CURLOPT_RETURNTRANSFER => true,
        ]);
        $response = curl_exec($curl);
        curl_close($curl);

        if ($response) {
            $response = json_decode($response, true);

            if ($response && array_key_exists('user_id', $response)) {
                return $response['user_id'];
            }
        }

        return false;
    }

    /**
     * @param string $accessToken
     *
     * @return string
     */
    protected function getValidationEndpoint($accessToken) {
        return 'https://www.googleapis.com/oauth2/v1/tokeninfo?access_token='. $accessToken;
    }
}