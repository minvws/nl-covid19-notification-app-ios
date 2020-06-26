/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import Security

struct Certificate {
    let secCertificate: SecCertificate

    init?(string: String) {
        let content = string.replacingOccurrences(of: "\n", with: "")

        guard let data = Data(base64Encoded: content),
            let secCertificate = SecCertificateCreateWithData(nil, data as CFData) else {
            return nil
        }

        self.secCertificate = secCertificate
    }
}

extension Certificate {
    struct SSL {
        static let root = Certificate(string: """
        MIIIaTCCBlGgAwIBAgIUdi6KL6dVrnqWuFYbsesck5ZAnUcwDQYJKoZIhvcNAQEL
        BQAwgYIxCzAJBgNVBAYTAk5MMSAwHgYDVQQKDBdRdW9WYWRpcyBUcnVzdGxpbmsg
        Qi5WLjEXMBUGA1UEYQwOTlRSTkwtMzAyMzc0NTkxODA2BgNVBAMML1F1b1ZhZGlz
        IFBLSW92ZXJoZWlkIE9yZ2FuaXNhdGllIFNlcnZlciBDQSAtIEczMB4XDTIwMDUy
        NzA5NDEwMVoXDTIxMDUyNzA5NTEwMFowgbYxHTAbBgNVBAUTFDAwMDAwMDAyMDAz
        MjE0Mzk0MDAxMQswCQYDVQQGEwJOTDETMBEGA1UECAwKR2VsZGVybGFuZDESMBAG
        A1UEBwwJQXBlbGRvb3JuMTgwNgYDVQQKDC9CZWxhc3RpbmdkaWVuc3QgQ0lFIChN
        aW5pc3RlcmllIHZhbiBGaW5hbmNpw6tuKTElMCMGA1UEAwwcYXBpLW90YS5hbGxl
        ZW5zYW1lbm1lbGRlbi5ubDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
        AMzN1sOoVsEYRjf7aOayaXyodQsAPvgu5k5CDAAPbpRsT3pX+jddNhpB3OJcrsQ1
        keskX6IFMfKupUX/oNsZdCVi967XbCzNAtQJtAH0/Mb8samCkoodesRLrhWMC4Bx
        VS6W7kwZbMMtr4nEEFIpRwrjeMgV3KZSqb5P67x8OodyC0tcZVO4Vfup7zxycZKX
        827Bdzgi5zaHk44PXYDMEWzQtvHSnwIeqXcAAzpAfCURIdkh/9ydDdUAJ6gZFgJa
        FkdtOsWnK82lYmZSHZUQFFe6T1a9IDnaTWxks9lm2b2e+Vu2G+8+b7ExPuqY1HD5
        DBNHDvuNYhTeM1jnsGey+W0CAwEAAaOCA58wggObMB8GA1UdIwQYMBaAFLfp0On/
        Zw7ZnAwHLpfUfkt5ePQgMHsGCCsGAQUFBwEBBG8wbTA8BggrBgEFBQcwAoYwaHR0
        cDovL3RydXN0LnF1b3ZhZGlzZ2xvYmFsLmNvbS9wa2lvc2VydmVyZzMuY3J0MC0G
        CCsGAQUFBzABhiFodHRwOi8vc2wub2NzcC5xdW92YWRpc2dsb2JhbC5jb20wJwYD
        VR0RBCAwHoIcYXBpLW90YS5hbGxlZW5zYW1lbm1lbGRlbi5ubDCCAToGA1UdIASC
        ATEwggEtMIIBHwYKYIQQAYdrAQIFBjCCAQ8wNAYIKwYBBQUHAgEWKGh0dHA6Ly93
        d3cucXVvdmFkaXNnbG9iYWwuY29tL3JlcG9zaXRvcnkwgdYGCCsGAQUFBwICMIHJ
        DIHGUmVsaWFuY2Ugb24gdGhpcyBjZXJ0aWZpY2F0ZSBieSBhbnkgcGFydHkgYXNz
        dW1lcyBhY2NlcHRhbmNlIG9mIHRoZSByZWxldmFudCBRdW9WYWRpcyBDZXJ0aWZp
        Y2F0aW9uIFByYWN0aWNlIFN0YXRlbWVudCBhbmQgb3RoZXIgZG9jdW1lbnRzIGlu
        IHRoZSBRdW9WYWRpcyByZXBvc2l0b3J5IChodHRwOi8vd3d3LnF1b3ZhZGlzZ2xv
        YmFsLmNvbSkuMAgGBmeBDAECAjAdBgNVHSUEFjAUBggrBgEFBQcDAgYIKwYBBQUH
        AwEwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC5xdW92YWRpc2dsb2JhbC5j
        b20vcGtpb3NlcnZlcmczLmNybDAdBgNVHQ4EFgQUc0eMU/WOhFRrkkrKlumWKNhJ
        vKEwDgYDVR0PAQH/BAQDAgWgMIIBAwYKKwYBBAHWeQIEAgSB9ASB8QDvAHYAu9nf
        vB+KcbWTlCOXqpJ7RzhXlQqrUugakJZkNo4e0YUAAAFyVYrVTgAABAMARzBFAiB4
        U4Y3T4l2HL1QK+/9uWw+ku+pk5yHJRjUZ+x7dNm6OwIhAIc5mXu8yieF4EyK4jcX
        5SfEU53/drmAyqODzsnNJ+wdAHUAVYHUwhaQNgFK6gubVzxT8MDkOHhwJQgXL6Oq
        HQcT0wwAAAFyVYrVXQAABAMARjBEAiBMwCkrbJHIfaqVwV4JLA8KVlnjJ7GDubF1
        WsGGFGDMfwIgDhzQbOjkc+5+wgsW7RB4I0nG3IfPmbPjln3HGogaLJMwDQYJKoZI
        hvcNAQELBQADggIBAIH25nInjq5iXOioxH9PpWS6MoIbQr5IYODdplkTlE/8KbNC
        N1uoCtxVLWgIDR+EJEdCHPaCGfdBJTQaxd7bHqGfcWsy6sw7T96npg5Bw9rklxLH
        I2Sq+0897GacVFCeqCZ4/Uuj0bOfPsOjIujvdmzMGz/wQH1awJ6/VPYQf0kHmO/L
        c4C4HSe3R0supPN+OUMFflQ/qVl11TxJyHtC8gjt3/JUuH7mKPtqxS5FoHJGkqOj
        0+dNfgvUjjMB8U/gvUBEVYCLzj2FdnjLh4mIMdthZ2kxEd6QKhDi21g2jkBVBiK+
        9kVr6xyrmQ9czNCt/mnMhPYbHMBp5jtO7XvdybOcPil9+7YpnHKavMgF/xkMjX9Z
        wPJc+LwDKZxLcGqN5OC8gJYscDYeQgqCl+UTeE8EfKjL/+PZIaUfAf2jMqWWnX08
        yhcVDcFvXUkZTjFbRH3JPKRwV5F0TctPOENf5rjNwmEACsi0HOCCtNw1N584+saL
        0HIseaH3DRlpFYPQoeORqC9YL9PV81sWjiWCi46FPkQgkkt73XwAUl2JDV9FsRW2
        GGMiVI0AMsiipF6Ui2WlcpdBhVSuvIIoDMYXz6n0+ggi8lx7GNeHU86vzkZTi6Pt
        GHrbsyrJ3j6PeRNYqRHDCwN8RBaqf0Xe9PqKXgU7Lt3RM8Czzyxq17V8mf09
        """)
    }
}
