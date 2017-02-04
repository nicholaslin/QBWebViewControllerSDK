;(function() {
    if (window.IOS) {
        return;
    }
  
    console.log("start init IOS Bridge");
  
    window.IOS = {
        registerHandler: registerHandler,
        handlerQuery:null,
        invokeCallback:null,
        callHandler: callHandler,
        hasHandler: hasHandler,
        hasHandlerQueue: [],
        _fetchQueue: _fetchQueue,
        _handleMessageFromNative: _handleMessageFromNative
    };
  
    var messagingIframe;
    var sendMessageQueue = [];
    var messageHandlers = {};

    var CUSTOM_PROTOCOL_SCHEME = 'iosjbscheme';
    var QUEUE_HAS_MESSAGE = '__IOSJB_QUEUE_MESSAGE__';

    var responseCallbacks = {};
    var uniqueId = 1;
  
  
    function registerHandler(handlerName, handler) {
        messageHandlers[handlerName] = handler;
    }

    function hasHandler(handlerName) {
        for(var i in IOS.hasHandlerQueue){
            if(IOS.hasHandlerQueue[i]==handlerName){
                return true;
            }
        }
        return false;
    }
  
  
    function callHandler(handlerName, data, responseCallback) {
        if (arguments.length == 2 && typeof data == 'function') {
            responseCallback = data;
            data = null;
        }else if(typeof responseCallback == 'number') {
    //鏄� callbackid
            var responseCallbackId = responseCallback;
            responseCallback = function(responseData){IOS.invokeCallback(responseCallbackId, responseData);}
        }
  
        if(typeof responseCallback == 'function') {
            _doSend({ handlerName:handlerName, data:data }, responseCallback);
        }
    }

    function _doSend(message, responseCallback) {
        if (responseCallback) {
            var callbackId = 'cb_'+(uniqueId++)+'_'+new Date().getTime();
            responseCallbacks[callbackId] = responseCallback;
            message['callbackId'] = callbackId;
        }
        sendMessageQueue.push(message);

    // console.log("doSend鍙戦�佽姹�!");

    //  messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    //  QBJSMessageHandler
        window.webkit.messageHandlers.QBJSMessageHandler.postMessage({message});
    // console.log("doSend鍙戦�佸畬鎴�!");
    }


    function _fetchQueue() {
    //         console.log('wvjb _fetchQueue');
        var messageQueueString = JSON.stringify(sendMessageQueue);
        sendMessageQueue = [];
        return messageQueueString;
    }

    function _dispatchMessageFromNative(messageJSON) {
        setTimeout(function _timeoutDispatchMessageFromNative() {
             var message = JSON.parse(messageJSON);
             
             var responseCallback;
             
             if (message.responseId) {
             
                 responseCallback = responseCallbacks[message.responseId];
                 if (!responseCallback) {
                     return;
                 }
             
                 responseCallback(message.responseData);
                 delete responseCallbacks[message.responseId];
             } else {
             
                 if (message.callbackId) {
                     var callbackResponseId = message.callbackId;
                     responseCallback = function(responseData) {_doSend({ responseId:callbackResponseId, responseData:responseData });};
                 }
             
                 var handler = messageHandlers[message.handlerName];
                 
                 if(!handler) {
                 //					console.log("no register handler: "+message.handlerName);
                     if(IOS.handlerQuery) {
                     console.log('has handlerQuery');
                     handler = IOS.handlerQuery(message.handlerName);
                     }
                 }
             
                 try {
                     handler(message.data, responseCallback);
                 } catch(exception) {
                     console.log("IOS: WARNING: javascript handler threw.", message, exception);
                 }
                 if (!handler) {
                     console.log("IOS: WARNING: no handler for message from native:", message);
                 }
            }
        });
    }

    function _handleMessageFromNative(messageJSON) {
        _dispatchMessageFromNative(messageJSON);
    }

    //  messagingIframe = document.createElement('iframe');
    //  messagingIframe.style.display = 'none';
    //  messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
    //  document.documentElement.appendChild(messagingIframe);
    //  
//    if(window.webkit) {
//        window.webkit.messageHandlers.wvjbInitMessageHandle.postMessage({});
//    }

    if(window.IOSJBCallbacks) {
        setTimeout(_callWVJBCallbacks, 0);
            function _callWVJBCallbacks() {
                var callbacks = window.IOSJBCallbacks;
                if (callbacks) {
                    delete window.IOSJBCallbacks;
                        for (var i=0; i<callbacks.length; i++) {
                            callbacks[i](IOS);
                        }
                }
            }
        }
    })();
