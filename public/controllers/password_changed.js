'use strict';
var app = angular.module('mainApp');
app.controller('PasswordChangedController', ['$scope', '$location', function ($scope, $location) {

    $scope.goToLogInView = function () {
        $location.path('/login');
    }

}]);
