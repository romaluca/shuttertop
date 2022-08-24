class I18n {

    constructor(lang) {
        this.lang = lang
        this.dicts = {
            "shuttertop_get_it": {
                en: "Find it for free on the ",
                it: "Scaricala gratuitamente dal "
            },
            "Scaricala": {
                en: "Get it",
                it: "Scaricala"
            },
            "terminato": {
                en: "finished",
                it: "terminato"
            },
            "terminato 1 giorno fa": {
                en: "expired 1 day ago",
                it: "terminato 1 giorno fa"
            },
            "terminato |n| giorni fa": {
                en: "expired |n| days ago",
                it: "terminato |n| giorni fa"
            },
            "manca 1 giorno": {
                en: "1 day left",
                it: "manca 1 giorno"
            },
            "mancano |n| giorni": {
                en: "|n| days left",
                it: "mancano |n| giorni"
            },
            "mancano |ore|": {
                en: "|ore| left",
                it: "mancano |ore|"
            }
        }
    }

    t(dict, params) {
        try {
            let tr = this.dicts[dict][this.lang]
            if (params !== undefined) {
                Object.entries(params).forEach(function (item) {
                    tr = tr.replace(`|${item[0]}|`, item[1])
                });
            }
            return tr;
        }
        catch (error) {
            console.warn(error, "traduzione mancante: ", dict, " lingua: ", this.lang, " params: ", params)
            return dict
        }

    }




}

export default I18n