// Exportar todas las funciones
exports.deleteAuthUser = require('./deleteAuthUser').deleteAuthUser;
exports.retryFailedDeletions = require('./deleteAuthUser').retryFailedDeletions;
exports.cleanupOldDeletionRecords = require('./deleteAuthUser').cleanupOldDeletionRecords;