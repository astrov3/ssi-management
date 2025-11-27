const STORAGE_KEY_PREFIX = 'wallet_name_';

const shortenAddress = (address, length = 6) => {
  if (!address || address.length <= length * 2 + 2) {
    return address ?? '';
  }
  return `${address.slice(0, length + 2)}...${address.slice(-length)}`;
};

export class WalletNameService {
  constructor(storage) {
    if (storage) {
      this.storage = storage;
    } else if (typeof window !== 'undefined' && window.localStorage) {
      this.storage = window.localStorage;
    } else {
      this.storage = null;
    }
  }

  _key(address) {
    return `${STORAGE_KEY_PREFIX}${address?.toLowerCase() ?? ''}`;
  }

  async saveWalletName(address, name) {
    if (!this.storage || !address) return;
    const trimmed = name?.trim() ?? '';
    if (!trimmed) {
      await this.deleteWalletName(address);
      return;
    }
    this.storage.setItem(this._key(address), trimmed);
  }

  async getWalletName(address) {
    if (!this.storage || !address) return null;
    return this.storage.getItem(this._key(address));
  }

  async deleteWalletName(address) {
    if (!this.storage || !address) return;
    this.storage.removeItem(this._key(address));
  }

  async getDisplayName(address, shortenLength = 6) {
    const name = await this.getWalletName(address);
    if (name) return name;
    return shortenAddress(address, shortenLength);
  }

  async getAllWalletNames() {
    if (!this.storage) return {};
    const entries = {};
    for (let i = 0; i < this.storage.length; i += 1) {
      const key = this.storage.key(i);
      if (key && key.startsWith(STORAGE_KEY_PREFIX)) {
        const address = key.replace(STORAGE_KEY_PREFIX, '');
        entries[address] = this.storage.getItem(key);
      }
    }
    return entries;
  }
}

export default WalletNameService;

