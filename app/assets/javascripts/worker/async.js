"use strict";
self.async = {
  allPromises(ary) {
    const aryLength = ary.length;
    return new Promise(function(resolve, reject) {
      let firstError = null,
        lastResult = null,
        firstErrorIdx = aryLength,
        completed = 0;
      const lastIdx = aryLength - 1;

      function lastCompleted() {
        if (firstErrorIdx < aryLength) {
          reject(firstError);
        } else {
          resolve(lastResult);
        }
      }
      function onsuccess(i) {
        return function(result) {
          if (i === lastIdx) {
            lastResult = result;
          }
          completed++;
          if (completed === aryLength) {
            lastCompleted();
          }
        }
      }
      function onfailure(i) {
        return function(err) {
          if (i < firstErrorIdx) {
            firstError = err;
            firstErrorIdx = i;
          }
          completed++;
          if (completed === aryLength) {
            lastCompleted();
          }
        }
      }

      for (let i = 0; i < aryLength; i++) {
        ary[i].then(onsuccess(i), onfailure(i));
      }
      if (aryLength === 0) {
        lastCompleted();
      }
    });
  }
};
