'use strict';

const express = require('express');

const router = express.Router();

router.get('/status', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'infra-web3-toolkit',
    version: 'v1',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
