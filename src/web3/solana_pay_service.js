'use strict';

const { Connection, PublicKey } = require('@solana/web3.js');
const { encodeURL } = require('@solana/pay');
const BigNumber = require('bignumber.js');

const DEVNET_USDC_MINT = '4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU';
const DEFAULT_RPC_ENDPOINT = 'https://api.devnet.solana.com';

class SolanaPayService {
  constructor(rpcEndpoint = process.env.SOLANA_RPC_ENDPOINT || DEFAULT_RPC_ENDPOINT) {
    this.connection = new Connection(rpcEndpoint, 'confirmed');
  }

  generateUsdcTransferUrl({ recipientAddress, amount, label, message, memo }) {
    const recipient = new PublicKey(recipientAddress);
    const parsedAmount = new BigNumber(amount);

    if (!parsedAmount.isFinite() || parsedAmount.lte(0)) {
      throw new Error('USDC amount must be a positive number.');
    }

    const url = encodeURL({
      recipient,
      amount: parsedAmount,
      splToken: new PublicKey(DEVNET_USDC_MINT),
      label,
      message,
      memo
    });

    const transferUrl = new URL(url.toString());
    transferUrl.searchParams.set('cluster', 'devnet');
    return transferUrl.toString();
  }

  async validateDevnetTransactionSignature(signature) {
    if (!signature || typeof signature !== 'string') {
      throw new Error('A valid transaction signature is required.');
    }

    // In production: add retry/backoff + jitter around RPC calls to absorb provider rate limits.
    const tx = await this.connection.getParsedTransaction(signature, {
      maxSupportedTransactionVersion: 0,
      commitment: 'confirmed'
    });

    if (!tx) {
      return { valid: false, reason: 'Transaction not found on devnet.' };
    }

    if (tx.meta?.err) {
      return { valid: false, reason: 'Transaction execution failed.', error: tx.meta.err };
    }

    return {
      valid: true,
      slot: tx.slot,
      blockTime: tx.blockTime
    };
  }
}

module.exports = {
  SolanaPayService,
  DEVNET_USDC_MINT
};
