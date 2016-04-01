'use strict';
var app = angular.module('mainApp');
app.controller('SetNewPasswordController', ['$scope', '$rootScope', '$routeParams', '$location', '$http', 'authenticationService',
    function ($scope, $rootScope, $routeParams, $location, $http, authenticationService) {

        var tokenKey = $routeParams.t;


        $scope.requestNewPassword = function () {
            $http({
                method: 'POST',
                url: '/user/password-reset',
                data: {
                    token_key: tokenKey,
                    new_password: $scope.newPassword
                }

            }).success(function (data, status, headers, config) {
                console.log(data);
                $location.path('/password-changed');
            }).error(function (data, status, headers, config) {
                console.log('Error');
                switch (status) {
                    case 400:
                        // Missing input
                    case 404:
                        switch (data) {
                            case 'token not found':
                                // Token with this token key not found. Have you already used the link?
                                $location.path('/password-link-invalid');
                                break;
                            case 'user not found':
                                // User with id specified in token data not found.  Ops, we got confused
                                $location.path('/confused');
                                break;
                            default:
                                break;
                        }
                        break;
                    case 409:
                        // Token expired
                        $location.path('/password-link-invalid');
                    default:
                        break;
                }

            });
        };

    }]);