'use strict';
var app = angular.module('mainApp');
app.controller('RegisterController', ['$scope', '$location', '$http', 'authenticationService',
    function ($scope, $location, $http, authenticationService) {

        $scope.register = function () {

            $http({
                method: 'POST',
                url   : '/user/register',
                data  : {
                    email:    $scope.email,
                    password: $scope.password
                }

            }).success(function (data, status, headers, config) {
                console.log(data);
                $location.path('/waiting-payment');

            }).error(function (data, status, headers, config) {
                console.log('Error');
                switch (status) {
                    case 409:
                        // Redirect to user-exists
                        $location.path('/user-exists');
                        break;
                    default:
                        break;
                }
            });
        }
    }
]);