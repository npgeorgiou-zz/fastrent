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

var app = angular.module("mainApp", ['ngRoute', 'rzModule', 'ui.bootstrap', 'infinite-scroll']);

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
        templateUrl: 'results.htm',
        controller: 'ResultsController'
    }).
    when('/register', {
        templateUrl: 'register.htm',
        controller: 'RegisterController'
    }).
    when('/waiting-payment', {
        templateUrl: 'waiting_payment.htm',
        controller: 'WaitingPaymentController'
    }).
    when('/login', {
        templateUrl: 'login.htm',
        controller: 'LoginController'
    }).
    when('/request-new-password', {
        templateUrl: 'request_new_password.htm',
        controller: 'RequestNewPasswordController'
    }).
    when('/set-new-password', {
        templateUrl: 'set_new_password.htm',
        controller: 'SetNewPasswordController'
    }).
    when('/settings', {
        templateUrl: 'settings.htm',
        controller: 'SettingsController'
    }).
    when('/profile', {
        templateUrl: 'profile.htm',
        controller: 'ProfileController'
    }).
    when('/user-exists', {
        templateUrl: 'user_exists.htm',
        controller: 'UserExistsController'
    }).
    when('/password-link-sent', {
        templateUrl: 'password_link_sent.htm',
        controller: 'PasswordLinkSentController'
    }).
    when('/password-link-invalid', {
            templateUrl: 'password_link_invalid.htm',
            controller: 'PasswordLinkInvalidController'
        }).
    when('/password-changed', {
        templateUrl: 'password_changed.htm',
        controller: 'PasswordChangedController'
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
                data  : {
                    token: authenticationService.getUserToken()
                }

            }).success(function (data, status, headers, config) {
                console.log(data);

                // Delete token
                authenticationService.logOutUser();
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
    var prefix = 'finders_keepers.';
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
    var prefix = 'finders_keepers.';

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

//app.directive('myMap', function() {
//    // directive link function
//    var link = function(scope, element, attrs) {
//        var map;
//
//        // map config
//        var mapOptions = {
//            center: new google.maps.LatLng(scope.lat, scope.lng),
//            zoom: 9,
//            scrollwheel: false,
//            disableDefaultUI: true
//        };
//
//        // init the map
//        function initMap() {
//            if (map === void 0) {
//                map = new google.maps.Map(element[0], mapOptions);
//            }
//        }
//
//        // place a marker
//        function setMarker(map, position, title, content) {
//            var marker;
//            var markerOptions = {
//                position: position,
//                map: map,
//                icon: 'https://maps.google.com/mapfiles/ms/icons/green-dot.png'
//            };
//
//            marker = new google.maps.Marker(markerOptions);
//        }
//
//        // show the map and place the marker
//        initMap();
//        setMarker(map, new google.maps.LatLng(scope.lat, scope.lng));
//    };
//
//    return {
//        restrict: 'E',
//        scope: {
//            lat: '=',
//            lng: '='
//        },
//        template: '<div class="gmaps"></div>',
//        replace: true,
//        link: link
//    };
//});
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
