"use strict";
self.async = {
  allPromises(ary) {
    const aryLength = ary.length;
    return new Promise(function(resolve, reject) {
      let completed = 0;
      let firstError = null,
        firstErrorIdx = aryLength;
      let lastResult = null,
        haveLastResult = false;
      const lastIdx = aryLength - 1;

      function lastCompleted() {
        if (firstErrorIdx < aryLength) {
          reject(firstError);
        } else {
          resolve(lastResult);
        }
      }

      for (let i = 0; i < aryLength; i++) {
        ary[i].then(function(result) {
          if (i === lastIdx) {
            lastResult = result;
            haveLastResult = true;
          }
          completed++;
          if (completed === aryLength) {
            lastCompleted();
          }
        }, function(err) {
          if (i < firstErrorIdx) {
            firstError = err;
            firstErrorIdx = i;
          }
          completed++;
          if (completed === aryLength) {
            lastCompleted();
          }
        });
      }
    });
  }
};
