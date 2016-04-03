'use strict';

// Extend prototypes

//Object.defineProperty(Array.prototype, 'chunk', {
//    value: function (chunkSize) {
//        var array = this;
//        return [].concat.apply([],
//            array.map(function (elem, i) {
//                return i % chunkSize ? [] : [array.slice(i, i + chunkSize)];
//            })
//        );
//    }
//});
Array.prototype.first = function () {
    return this[0];
};
Array.prototype.last = function () {
    return this[this.length - 1];
};

var app = angular.module('mainApp', ['ngRoute', 'rzModule', 'ui.bootstrap', 'infinite-scroll', 'ui.bootstrap.modal']);

app.run(["$rootScope", '$templateCache', 'authenticationService',
    function ($rootScope, $templateCache, authenticationService) {

        $rootScope.$on('$routeChangeStart', function(event, next, current) {
            if (typeof(current) !== 'undefined'){
                $templateCache.remove(current.templateUrl);
            }
        });

        $rootScope.loggedIn = authenticationService.getUserToken() !== null;
    }]);


app.config(['$routeProvider', function($routeProvider) {
    $routeProvider.
    when('/results', {
        templateUrl: 'views/results.htm',
        controller: 'ResultsController'
    }).
    when('/register', {
        templateUrl: 'views/register.htm',
        controller: 'RegisterController'
    }).
    when('/waiting-payment', {
        templateUrl: 'views/waiting_payment.htm',
        controller: 'WaitingPaymentController'
    }).
    when('/login', {
        templateUrl: 'views/login.htm',
        controller: 'LoginController'
    }).
    when('/request-new-password', {
        templateUrl: 'views/request_new_password.htm',
        controller: 'RequestNewPasswordController'
    }).
    when('/set-new-password', {
        templateUrl: 'views/set_new_password.htm',
        controller: 'SetNewPasswordController'
    }).
    when('/settings', {
        templateUrl: 'views/settings.htm',
        controller: 'SettingsController'
    }).
    when('/profile', {
        templateUrl: 'views/profile.htm',
        controller: 'ProfileController'
    }).
    when('/user-exists', {
        templateUrl: 'views/user_exists.htm',
        controller: 'UserExistsController'
    }).
    when('/password-link-sent', {
        templateUrl: 'views/password_link_sent.htm',
        controller: 'PasswordLinkSentController'
    }).
    when('/password-link-invalid', {
            templateUrl: 'views/password_link_invalid.htm',
            controller: 'PasswordLinkInvalidController'
        }).
    when('/password-changed', {
        templateUrl: 'views/password_changed.htm',
        controller: 'PasswordChangedController'
    }).
    when('/goodbye', {
        templateUrl: 'views/goodbye.htm',
        controller: 'GoodbyeController'
    })
        .otherwise({
        redirectTo: '/results'
    });
}]);
app.controller('MainController', ['$scope', '$rootScope', '$location', '$http', 'authenticationService',
    function ($scope, $rootScope, $location, $http, authenticationService) {

        $scope.logOut = function(){
            $http({
                method: 'POST',
                url   : '/user/logout',
                headers: {
                    'Authorization': authenticationService.getUserToken()
                }
            }).success(function (data, status, headers, config) {
                console.log(data);

                // Delete token and settings
                authenticationService.logOutUser();
                $location.path('/results');
            }).error(function (data, status, headers, config) {
                console.log('Error')
                switch (status) {
                    case 404:
                        // No user with this token found
                        authenticationService.logOutUser();
                        $location.path('/confused');
                        break;
                    default:
                        break;
                }
            });
        }
    }]);

app.service('settingsService', function () {
    var prefix = 'fastrent.';
    //var userSettings = null;
    var defaultSettings = {
        site:   ['Boligportal', 'Dba', 'Boligbasen'],
        region: ['Hovedstaden'],
        type:   ['Apartment', 'House', 'Room'],
        minRent: 3000,
        maxRent: 10000,
        emailFrequency: 60 * 24
    };

    function setSettings(settings) {
        localStorage.setItem(prefix + 'user.settings', JSON.stringify(settings));
        //userSettings = settings;
    };
    function getSettings() {
        var userSettings = localStorage.getItem(prefix + 'user.settings');
        return (userSettings === null) ? getDefaultSettings() : JSON.parse(userSettings);
    };
    function clearSettings() {
        localStorage.removeItem(prefix + 'user.settings');
    };
    function getDefaultSettings() {
        return defaultSettings;
    };
    return {
        setSettings:   setSettings,
        getSettings:   getSettings,
        clearSettings: clearSettings
    }
});

app.service('authenticationService', ['$rootScope', 'intervalService', 'settingsService', function($rootScope, intervalService, settingsService) {
    var prefix = 'fastrent.';

    function logInUser(token) {
        localStorage.setItem(prefix + 'user.token', token);
        $rootScope.loggedIn = true;
    };
    function logOutUser() {
        localStorage.removeItem(prefix + 'user.token');
        $rootScope.loggedIn = false;
        intervalService.unsetInterval();
        settingsService.clearSettings();
    };
    function getUserToken() {
        return localStorage.getItem(prefix + 'user.token');
    };
    function isUserLoggedIn() {
        return localStorage.getItem(prefix + 'user.token') !== null;
    };

    return {
        logInUser: logInUser,
        getUserToken: getUserToken,
        logOutUser: logOutUser,
        isUserLoggedIn: isUserLoggedIn
    }
}]);
app.service('intervalService', function () {
    var interval = null;

    function setInterval(fetchInterval) {
        interval = fetchInterval;
    };
    function getInterval() {
        return interval;
    };
    function unsetInterval() {
        clearInterval(interval);
        interval = null
    };
    function isIntervalSet() {
        return interval !== null;
    };

    return {
        setInterval: setInterval,
        getInterval: getInterval,
        unsetInterval: unsetInterval,
        isIntervalSet: isIntervalSet
    }
});
//app.service('userService', ['$http', '$q', function($http, $q) {
//    function loggedIn() {
//        $http({
//            method: 'POST',
//            url   : '/user/logged-in',
//            data  : {
//                token: 'asdfsa87fsd9a8fasin'
//            }
//
//        }).success(function (data, status, headers, config) {
//            console.log(data);
//        }).error(function (data, status, headers, config) {
//            console.log('Error');
//        });
//    };
//    return {
//        loggedIn: loggedIn
//    }
//}]);

app.directive("compareTo", function() {
    return {
        require: "ngModel",
        scope: {
            otherModelValue: "=compareTo"
        },
        link: function(scope, element, attributes, ngModel) {

            ngModel.$validators.compareTo = function(modelValue) {
                return modelValue == scope.otherModelValue;
            };

            scope.$watch("otherModelValue", function() {
                ngModel.$validate();
            });
        }
    };
});
app.directive('modal', function(){
    return {
        template:
        '<div class="modal" tabindex="-1" role="dialog" aria-labelledby="myLargeModalLabel" aria-hidden="true">' +
        '<div class="modal-dialog">' +
        '<div class="modal-content" ng-transclude></div>' +
        '</div>' +
        '</div>',
        restrict: 'E',
        transclude: true,
        replace:true,
        scope:{visible:'=', onSown:'&', onHide:'&'},
        link:function postLink(scope, element, attrs){

            $(element).modal({
                show: false,
                keyboard: attrs.keyboard,
                backdrop: attrs.backdrop
            });

            scope.$watch(function(){return scope.visible;}, function(value){

                if(value == true){
                    $(element).modal('show');
                }else{
                    $(element).modal('hide');
                }
            });

            $(element).on('shown.bs.modal', function(){
                scope.$apply(function(){
                    scope.$parent[attrs.visible] = true;
                });
            });

            $(element).on('shown.bs.modal', function(){
                scope.$apply(function(){
                    scope.onSown({});
                });
            });

            $(element).on('hidden.bs.modal', function(){
                scope.$apply(function(){
                    scope.$parent[attrs.visible] = false;
                });
            });

            $(element).on('hidden.bs.modal', function(){
                scope.$apply(function(){
                    scope.onHide({});
                });
            });
        }
    };
});
app.directive('modalHeader', function(){
    return {
        template:
        '<div class="modal-header">' +
        '<button type="button" class="close" data-dismiss="modal" aria-label="Close">' +
        '<span aria-hidden="true">&times;</span>' +
        '</button>' +
        '<h4 class="modal-title">{{title}}</h4>' +
        '</div>',
        replace:true,
        restrict: 'E',
        scope: {title:'@'}
    };
});
app.directive('modalBody', function(){
    return {
        template:'<div class="modal-body">{{body}}</div>',
        replace:true,
        restrict: 'E',
        scope: {body:'@'}
    };
});
app.directive('modalFooter', function(){
    return {
        template:'<div class="modal-footer" ng-transclude></div>',
        replace:true,
        restrict: 'E',
        transclude: true
    };
});