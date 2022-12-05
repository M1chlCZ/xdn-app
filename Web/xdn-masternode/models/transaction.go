package models

var TXTest string = `{
    "txid" : "1e6a4702c2069b6b2865342c5736468e226a604aad8cdf50903f899a743e624c",
    "version" : 1,
    "time" : 1670174530,
    "locktime" : 0,
    "vin" : [
        {
            "txid" : "1c4439204a5833beeb426cc8a91fcf6dcc502fb162ebca957cdda459d0219e66",
            "vout" : 0,
            "scriptSig" : {
                "asm" : "3044022040af7b07541fc355397b95c5d374cf80de4a45f2d17740dfb6584582c500b35b02207d7b295b1a412fb4642e0bdfb627fab5c790b8e7f02e04e090a54de96052faf801 021eb66f5d7c70739576efba0b5e807376a040073699c6bcc3fbc4a9ba7884cbae",
                "hex" : "473044022040af7b07541fc355397b95c5d374cf80de4a45f2d17740dfb6584582c500b35b02207d7b295b1a412fb4642e0bdfb627fab5c790b8e7f02e04e090a54de96052faf80121021eb66f5d7c70739576efba0b5e807376a040073699c6bcc3fbc4a9ba7884cbae"
            },
            "sequence" : 4294967295
        },
        {
            "txid" : "5add698239148e27d5660a3cf2875238d9efd3515fe96b3fc0784e8dc783d1d7",
            "vout" : 0,
            "scriptSig" : {
                "asm" : "30440220608104d2eab366736dd0b42e51ae4b17f1247f632b434e75d18abb49c1041a4b0220214aa7a20d127d44674677221fafa83fb7629f024d40267b38657b8a5186fbdd01 021eb66f5d7c70739576efba0b5e807376a040073699c6bcc3fbc4a9ba7884cbae",
                "hex" : "4730440220608104d2eab366736dd0b42e51ae4b17f1247f632b434e75d18abb49c1041a4b0220214aa7a20d127d44674677221fafa83fb7629f024d40267b38657b8a5186fbdd0121021eb66f5d7c70739576efba0b5e807376a040073699c6bcc3fbc4a9ba7884cbae"
            },
            "sequence" : 4294967295
        }
    ],
    "vout" : [
        {
            "value" : 0.00100000,
            "n" : 0,
            "scriptPubKey" : {
                "asm" : "OP_DUP OP_HASH160 76d7b36f355b6d6e49f18eb736dc9712c8e6e786 OP_EQUALVERIFY OP_CHECKSIG",
                "hex" : "76a91476d7b36f355b6d6e49f18eb736dc9712c8e6e78688ac",
                "reqSigs" : 1,
                "type" : "pubkeyhash",
                "addresses" : [
                    "dQFfka8awGqoWuaLKnkBUcpHCzpEAQFaE2"
                ]
            }
        },
        {
            "value" : 9.99300000,
            "n" : 1,
            "scriptPubKey" : {
                "asm" : "OP_DUP OP_HASH160 b74cc394761bfb7d19109b273b2622f9f38640e6 OP_EQUALVERIFY OP_CHECKSIG",
                "hex" : "76a914b74cc394761bfb7d19109b273b2622f9f38640e688ac",
                "reqSigs" : 1,
                "type" : "pubkeyhash",
                "addresses" : [
                    "dW8VEXurvxeJ1dMer6JoR6RSb3u3MnmMQW"
                ]
            }
        }
    ],
    "amount" : -9.99300000,
    "fee" : -0.00400000,
    "confirmations" : 76,
    "bcconfirmations" : 76,
    "blockhash" : "00000000000b52c179743e63f4aca3636a30a82f1e394f59f011a1561e423a07",
    "blockindex" : 2,
    "blocktime" : 1670174540,
    "walletconflicts" : [
    ],
    "timereceived" : 1670174535,
    "details" : [
        {
            "account" : "",
            "address" : "dQFfka8awGqoWuaLKnkBUcpHCzpEAQFaE2",
            "category" : "send",
            "amount" : -0.00100000,
            "fee" : -0.00400000
        },
        {
            "account" : "",
            "address" : "dW8VEXurvxeJ1dMer6JoR6RSb3u3MnmMQW",
            "category" : "send",
            "amount" : -9.99300000,
            "fee" : -0.00400000
        },
        {
            "account" : "WRETCH21",
            "address" : "dQFfka8awGqoWuaLKnkBUcpHCzpEAQFaE2",
            "category" : "receive",
            "amount" : 0.00100000
        }
    ]
}`

type GetTransactionXDN struct {
	Txid     string `json:"txid"`
	Version  int    `json:"version"`
	Time     int    `json:"time"`
	Locktime int    `json:"locktime"`
	Vin      []struct {
		Coinbase string `json:"coinbase"`
		Sequence int    `json:"sequence"`
	} `json:"vin"`
	Vout []struct {
		Value        float64 `json:"value"`
		N            int     `json:"n"`
		ScriptPubKey struct {
			Asm       string   `json:"asm"`
			Hex       string   `json:"hex"`
			ReqSigs   int      `json:"reqSigs"`
			Type      string   `json:"type"`
			Addresses []string `json:"addresses"`
		} `json:"scriptPubKey"`
	} `json:"vout"`
	Amount          float64       `json:"amount"`
	Confirmations   int           `json:"confirmations"`
	Bcconfirmations int           `json:"bcconfirmations"`
	Generated       bool          `json:"generated"`
	Blockhash       string        `json:"blockhash"`
	Blockindex      int           `json:"blockindex"`
	Blocktime       int           `json:"blocktime"`
	Walletconflicts []interface{} `json:"walletconflicts"`
	Timereceived    int           `json:"timereceived"`
	Details         []struct {
		Account  string  `json:"account"`
		Address  string  `json:"address"`
		Category string  `json:"category"`
		Amount   float64 `json:"amount"`
	} `json:"details"`
}
