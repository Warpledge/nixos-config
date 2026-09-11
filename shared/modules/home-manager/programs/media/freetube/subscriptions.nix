{
  config,
  lib,
  pkgs,
  ...
}: let
  #=====================================================================#
  # FREETUBE SUBSCRIPTIONS
  #=====================================================================#
  # programs.freetube only manages settings.db, so profiles.db is written
  # the same way home-manager writes that: from a store file, leaving the
  # live file writable so the app keeps working.
  #
  # Seed-only: profiles.db is written just once, when it does not exist
  # (fresh install, new machine). After that the app owns it, so
  # subscribing and unsubscribing in the GUI survives every rebuild.
  # The list here is a snapshot - recapture it when you want the repo
  # to match reality again.
  sub = id: name: thumbnail: {inherit id name thumbnail;};

  #--------------------------------------------------------------------#
  #-- Subscriptions
  #--------------------------------------------------------------------#
  subscriptions = [
    (sub "UC3unJShm6iXtw9QgDnb9KPg" "66Samus" "https://yt3.googleusercontent.com/EfKWbYG7Pr-EVjDQn8kmr9xf-5UJZpJZx37YZlyFAumzf_rt7O0rypzZNa6H2snCkyMT3a9xIw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCpExd_4igz7vIC0hgeY-uNg" "AdityaG" "https://yt3.googleusercontent.com/TzD4oNVZU4vJSzTL7Pb6eTKg7KVLoNh4-WlFv1RXdRs0kmsieiuKXCSS05Pe0kpQhP3YUiUWtQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCIgnGlGkVRhd4qNFcEwLL4A" "AI Search" "https://yt3.googleusercontent.com/GV5UTW2IlP29PhsLKm65ue4LZYXxMyPV5YQdfE6GVgv9KH1_y_8kCirPGfpVn9yTJuNBvVHktEE=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCupQd0e1leK4-Mj1wSfnkoQ" "al jokes" "https://yt3.googleusercontent.com/93ns_GxAFCbk_u_lNAeTDJP5pBQuBD-Ccc3X9Gux5SU_EN49XzB4SJ9hDPS20vK3GzJHwonlKg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCcCtwWZlbENdsCnF2Nzjivg" "AlkaizerSenpai" "https://yt3.googleusercontent.com/ytc/AIdro_mqMuNaekpxL38C3qzOxr7t_a-QUVBSp-lRRElOU35YVQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC6jUsIEZ2F875OB2Be84cpA" "Ampersand" "https://yt3.googleusercontent.com/e_Iqax0Nciq9_37f8TYhsy6qC_qvoxWCtzD1ZdbR1ZGiVgmO0cyDcn219Y8K4foElht8m9Z19g=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCR0J2NYGuC8epsa1O4DMmXQ" "Arknights Official - Yostar" "https://yt3.googleusercontent.com/ytc/AIdro_kS7_YzlYPQz0ba4-q4meB6exa5_aHcFUVlpLZ-5HfT-g=s176-c-k-c0x00ffffff-no-rj-mo")
    (sub "UCowPaVRBzg8CE6K4CB6LJfw" "Arknights: Endfield" "https://yt3.googleusercontent.com/OuleuixkEAEEJawVB6v4UzEDk_O83SlbMpngrpI1eLw2Pd0o0vElaCAcoXmhdrPM1D8PpbuFVQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCIQ-5XCjglwZ9OYVaESUqjw" "Avantgarde Music" "https://yt3.googleusercontent.com/ytc/AIdro_kRQYfUyRY0suDVAvrNpyPT1cLXYQhh75pJTAt7bPlEZg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCv6GlCIlfC9hLW8shg4cRyw" "AverageGregTechPlayer" "https://yt3.googleusercontent.com/ZoaytrhzBtlU3uZkRsc_jCmgHhaYyksgIZbfQf-vm9oAh199wzcKJ9uoemzfp0rr4Wiy5H9c=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCcybVOrBgpzUxm-mlBT0WTA" "Bacon_" "https://yt3.googleusercontent.com/ytc/AIdro_lA0nn0joCndTNUA6mxmtJadkXxHTBqAlm78leRCVqr5Q=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCYGDiVemmhY_Q1M-hKp4fvw" "big boss" "https://yt3.googleusercontent.com/ytc/AIdro_m4kIuiEKXY-kFWf7h3u1DWdu081Kv9VynucwjeK3pOtWg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC2Z5-gCZU3rqLvmBGCOdTQg" "Bionicfactory1" "https://yt3.googleusercontent.com/ZKej02-G71SZ55PeJOXl98DwnbR_aXzAy2mAGvqOrUevJTkZCCgcjbVXTPVsFmHIJjP0EWPK7vA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCzCWehBejA23yEz3zp7jlcg" "Black Metal Promotion" "https://yt3.googleusercontent.com/ytc/AIdro_kjUgTst6YXNAsQ4XCyhoovZqMUq9QV_IPmv9_Jjj_8buo=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCQOjhHT7NdXF1TiZE5lzxBw" "Bladed Angel" "https://yt3.googleusercontent.com/pL4fabC9MUvUtlB2vS_AJLorJO077Ou4pygLOWTRnIaptDtx_dIMqSBjWJnvhEJ4CkETE_HWKw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCMksEtt1yyGOZTf0YBI7LDA" "Blake " "https://yt3.googleusercontent.com/_R28MkwCK0cnhcp4HR8Ey2ELQXIs7AT_q1D4EwlvDM4coeCcFZczYBPR6MCHNjz60Gz7nnpvKA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCZXW8E1__d5tZb-wLFOt8TQ" "Bog" "https://yt3.googleusercontent.com/R5ETJ2TjSi61fNkFbXuxc2n4bEMv92Evt9oFOIsmxpiJeBpQCtjfJeLznOEZQ7QQbZ5zg80Y=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCNreGFHM0T2WRkuVXmu459A" "Bombshell" "https://yt3.googleusercontent.com/i2G3zIcVOLSjXRH5fZBdOtrebyN7CbepbIT3pped7ERc3bWvE5MSEEoovCCK_XizYqgRzKfLf5Y=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC3mI3dDFrZ5PHFPx1H0TCvQ" "Bradley Hall" "https://yt3.googleusercontent.com/b7lzIz89hAYo-Y_TTfNdyJjzy6irSEX8gLS36rU3eBIvH2YbEy1Sm5hYp_XqWLcpaynV6I6pOw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCuyLvQnJxIFVXAp7yY4QTcA" "brome" "https://yt3.googleusercontent.com/BXUKcNrX4p0ufIXZ2UN8riY0VCaWxDLurBCZFXotPg2o4VOAUxhlafxTw74oOD8-PV4CZzknyYI=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCk6mN7s3Orj0LbmHdzVg05A" "Bub Games" "https://yt3.googleusercontent.com/ytc/AIdro_n0e1dmQZtZsf35bOfkuVy5XYRxb90Lyu3aTUzZn_bgg5I=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCEIGk89dDLYACKrneSMfdQQ" "CaseOh Moments" "https://yt3.googleusercontent.com/6PDCoShHynWRQ5I70ecvJtxaqVj866lmhZmwey7fUYLdCJglAYzquOzEWRaozQbMqcyS1N35=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCSDUsSu7t8WxByRYZz1jaYA" "Cemetery Riffs" "https://yt3.googleusercontent.com/lnPMHCTspCoEB06beFecyyWK2p34UmGKJOlMiwiIfl6R7E7xKYAPH6rC0iOHekj49Q5yhgrshg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCZjh3L41c2n9vu1yaV9TX0g" "ChadCat" "https://yt3.googleusercontent.com/RVRwKXz0n7ej4tyaqps3fQj1Ly1bcmu-GbvAEWputTJsQXiax7rsJY8akqMF0tzeMpYUcu_oEA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCgeE4uJZqmsQBURNPKs9Haw" "Chainbrain" "https://yt3.googleusercontent.com/ytc/AIdro_mm88LPBJhoaTHC2GowSxpv_n2ojoD7TtEfC9uCqc3ls3o=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCAi_uNeDWRXj8C8yw358gWw" "CharlesBerthoud" "https://yt3.googleusercontent.com/ytc/AIdro_kBGqXG-DYUkhaGnAXBGatbT_O5n86ctUfK-q5vicw4-oA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCg6gPGh8HU2U01vaFCAsvmQ" "Chris Titus Tech" "https://yt3.googleusercontent.com/ZfxzyYBtuZRA4ju9t5veuPJJEs-UPkExpnkngHIMdw8KILfIKSmaoYJ6MTpQ5MXUkt5mFPpbBA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC6dKynwWVCYOcyllwU8aAaA" "Chris Wilson" "https://yt3.googleusercontent.com/cfEbIPae4imeLScHvP_7m0MtUKMaK6xIXW2zfijEzsMI0xV9OOZGZE1oVvap-VNNp_q9iu7LpQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCId_okLITilJmxba3jhV9Gg" "coolmanvan" "https://yt3.googleusercontent.com/arsvOMdemQPQmILkonAlTK0D0B0YTVyuKOUwa8RNDlUgC4tovEVP_ksR_bKlfF5m6WHikwQepQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCP_eG7JBgRWNlNIOLYS6GZA" "crin" "https://yt3.googleusercontent.com/Bl_9LG_tfE8-PA9_4Bi4hOKdxirTAfYWzDJMRp3D94ps08QAIkVrU9sYF1wPqQCec9f8GiAl=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCxbOjzYaOGbZFYKP3DR4gBA" "Dallas Soup" "https://yt3.googleusercontent.com/MedoYTwqGreHNtTj74E-QSyn686eR57wvHKxyrLdwOYpeEYZAjMeES-LBkGHTaldZubNEo9Yx2w=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCY-PrcA-mjq3OhgsAH9C52A" "Dan Dingle" "https://yt3.googleusercontent.com/o-xu__wrO6ZjswawSkJe103TqtzWtfyJuX2xKFkQ0CpHBxz4oiFquBj15QxYKduHa-vdhu9Msg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCAYJSYhkQOiICxDZkzVMl5w" "Darth Microtransaction" "https://yt3.googleusercontent.com/ytc/AIdro_nQadBSFcm7l7YtNwrqXSb_qXF8KJtFtiAB20RNEulBGMg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCV3_xcWQ1J55f1kehK4-TOw" "Dean Lamb" "https://yt3.googleusercontent.com/feIE_PxWmO6nu2i0x0ZjeOhZtc_367ZtGyyyUZP_qiVbk5uoX_dWvXZ9M4C-QFB4ylWyIC8A9A=s176-c-k-c0x00ffffff-no-rj")
    (sub "UChSPFhlKhvjpvBhO1gyDhVQ" "Debemur Morti Productions" "https://yt3.googleusercontent.com/bQqdGNthxT2v4Ft15JYvHn9LqR084bEina6TWPq5KwcGBtkSNjM2GxApODbPdy7zCaXh_Q_9=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCUOKq4-XMOzHIAGdunZROqQ" "DerangedDoomer" "https://yt3.googleusercontent.com/ULI3qBQStc0W6idxbK1qAhv61SQMiUOEj3vYSxtfuiHxoEu_AoNXe-_LdRx4fDd5WaT4SzgJpas=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCWL2Fx4hs7xtKOx8-lbMw2w" "DonutOperatorTV" "https://yt3.googleusercontent.com/nQa4Q8O7QtEzqWR9jm9h-vZ5at8eslhb1MeJFmbFg_kneba2tifpGcsivaV9gjmHbRmBhjV4n48=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC-TmKEwMYER5DdoEMoF-hsw" "DonutOperatorTV Clips" "https://yt3.googleusercontent.com/GGfKgMda3kX7NU3l5NuxhuHK6JDFBDRkB4PnZZoBPUZ3LL9JFIYPFzJDcxWY92Kq1KUx416Y=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCo0-VCHchPIG3JtJlIQnFew" "DoshDoshington" "https://yt3.googleusercontent.com/ytc/AIdro_nAY1rUirI0vhI82HYgyeR5KTtF8wOG8htuOBokKVoN4g=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCrsIHfOar07vEPXP1Ng9T8g" "EiZEN" "https://yt3.googleusercontent.com/PWyMjAMuycuzXJhDtPQkGV7cFScop8d4shgle9UQA3EOhspbVwGhhwyMpt95BOxDAH7y5veX8tw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCvIzz-SZdAyOBfwSFB-yIAw" "Farvann" "https://yt3.googleusercontent.com/ytc/AIdro_lCMLq86Pa322yKrzZe_4ceUvb20GU7Lf7nOcyRHSc-Lb4=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCsBjURrPoezykLs9EqgamOA" "Fireship" "https://yt3.googleusercontent.com/3fPNbkf_xPyCleq77ZhcxyeorY97NtMHVNUbaAON_RBDH9ydL4hJkjxC8x_4mpuopkB8oI7Ct6Y=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCjmigXcFhjldwmVBpdLoARg" "FrostByte262" "https://yt3.googleusercontent.com/0xOPPOI3wUVQZsauIMe24xuCuyZaMsidIWiLTWdWmkHzGcGhKvQWGb6ANzkGXV5bF6GtQOe5=s176-c-k-c0x00ffffff-no-rj")
    (sub "UChIs72whgZI9w6d6FhwGGHA" "Gamers Nexus" "https://yt3.googleusercontent.com/ytc/AIdro_n50Rj8oqwUnusv4I6_DllKflZrSdSxmXhYvpHs0hOEj5o=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC0poNmhV59dDVE6o3gxy5lA" "GitGudWO" "https://yt3.googleusercontent.com/UxkjhEPUFmSGsFQ5SayWm1md1lVVEAAHrBqb7zVRPGJK8r5qkWPzy8WaXtL5W5pWaQ789uRMj4w=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCfJWiiMCyIhUokO69TlF5Ag" "Guillaume Vrac" "https://yt3.googleusercontent.com/ZEKvGJeKJKrcYa2OOSZd_sAAF0qUZgsYkWgvCvHM-a3kSYppIjYaLeGEdUpsJ15VYC5hENlqibM=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCZ8f38Vn2jq950NQiS5Qx4Q" "gupp" "https://yt3.googleusercontent.com/qyFNU4yDsPBF-xLdDbBPSlE8XEw2pkADY7os-IYRjnykADnomoZpn3VLdQuN0elGdu1QuOCMV00=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCNnaNSEzrD5pwDj5sKfklyQ" "HamCorp" "https://yt3.googleusercontent.com/DLg7uiVIBJYwNm1O8AQWPdrdw-DWJXecHS8Xxx8r1SAr_quOEm386WDu0Pm2bgKXaCs4SdVS=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCJzyqivEVGq4NVOdpd8HLGg" "Hecuba" "https://yt3.googleusercontent.com/3NWdbzkkP3qR2wjQyDp4xI2xeXUucVTKCOKJGSSj8ivawGEF0BzwI543TU008NYJKaV1eBuM=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCvwFAruyd5WGqi9qUoB91_g" "IGoByLotsOfNames" "https://yt3.googleusercontent.com/9kcfUw7PQdkw1lnXnLPxuCA2vtcI79Y3SpmI-Vq4eGHHuDoEFeqgsHcqhX0m_jufQPE-opKC=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCVMPToqu3B8JvoceelWxTyQ" "Imperial Circus Dead Decadence Official" "https://yt3.googleusercontent.com/uNTMCuNhRVhVysu0lc31yRiutWTnFmI60kboT5VRY17_cg8VSzTXTpU_0X2u8RD5cK4v2ynwj1Q=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCt8CJiye87FMbEwt0npPMuQ" "Indie Games Hub" "https://yt3.googleusercontent.com/hfEnjPEwoZa-qRQKYazB1GyP2vv65B9dM7Z_8-uj1vvaQGFyrfiVnBSz9eSWFP3_DmUknLCNMsM=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCyWDmyZRjrGHeKF-ofFsT5Q" "Internet Comment Etiquette with Erik" "https://yt3.googleusercontent.com/ytc/AIdro_kyLaewfoFi575QnPMYwzhXgBL8foNbH7mkzmh9r1n9Yg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCR1D15p_vdP3HkrH8wgjQRw" "Internet Historian" "https://yt3.googleusercontent.com/KxPzYd4N5kY8r1idQQKRZ_ulN6VYrkudnFJdXUINM3LcnpIcK4DJUrZFkTOnB11oh5Y0FWT25A=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC78mJyZPMa_OG08KLHjhODw" "Jaden Williams" "https://yt3.googleusercontent.com/Gtk-7feBEyXzjWJOf_NLUZxhcolX79csPMAmuoV0FHOUeCnPl6_XdHkhvcPTTBa-QjwfHh_SmQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCwwRzW41YdhO2O0klNkttUA" "JD Delay" "https://yt3.googleusercontent.com/sZ3-IA1eWPy4JuW7ETXJgKy3taVL7VK0qFfijPRjB-LYvTsmH-eQ2b9uOtkQNeCW2GSrvrm-=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC3Lmytq3AlvcJ-34If_jDyw" "Jehtt" "https://yt3.googleusercontent.com/ytc/AIdro_kWNZgCXsEemKHT1V5J6kHM5ebGI1rqxYhuJyNO8BHgPg0=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCdJdEguB1F1CiYe7OEi3SBg" "JonTronShow" "https://yt3.googleusercontent.com/ytc/AIdro_mSrXgDqI8wbFAqBf11i83MWuRa0aHwl-FPcWCpxdjNInU=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCFfydLsSi1cN547lVC6ewUw" "Jordan & Tommy Bonnevialle" "https://yt3.googleusercontent.com/GD03ZOZaJrvirw9W3CU8iQ0efkqxauVRX4j7ricZf7ZOGU6CzWsGNxFJEi8EEZ5cm34-AA2D5A=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCapAxx_bMPdOEl2SQxg2HAw" "Kharax82" "https://yt3.googleusercontent.com/ytc/AIdro_keybEehJAziN0uyRMeM_Gxr48RWws8ltfrlYDICkWO=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCjdQaSJCYS4o2eG93MvIwqg" "Kilian Experience" "https://yt3.googleusercontent.com/ytc/AIdro_lxO2XdP5VChQgfU9XQxTBk_lL7UgJtkq1sdXbEh2zMtg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCYKqSTaebCjNrQSPZ3_uHcw" "kukkikaze" "https://yt3.googleusercontent.com/0jfzBFlGz4en2ufzQuOHfr82WnVqVbCReatVQ5G96HJjKEsNDHhUjPwAa-t-hCh87Yfnj0Xitw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCWwuijyo4x78iXup5hOvkbw" "KyoStinV" "https://yt3.googleusercontent.com/yeBCzRTWlea7CA8ve6ho6vERiWKR_bEewt8eMN8BJmS6Dr4yjuh0JzAiBxhj2225bSwwZpNUVw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCeA2_nawteB3Bn-sF9CBGxg" "Lappy" "https://yt3.googleusercontent.com/OzqwtITDk_fY-z1AdPXep3709y1H8BVTUZ3AHFGZTPcWWmwap_aBBVHNvY_pPqwqmBjse-Muew=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCto7D1L-MiRoOziCXK9uT5Q" "Let's Game It Out" "https://yt3.googleusercontent.com/ytc/AIdro_nRBG_p61vExRtIGDam4OcTadOi1xwsoZX9sImEJk9f76Y=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCQDZ2iQNBgu5NPHyuki7MfA" "LosPlug" "https://yt3.googleusercontent.com/ytc/AIdro_l7oBWBvrmBDn-tfVLc3aZhD5xr-u4yr74OZu3gaIQbS0s=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC_9ChMcegQVpwQootbKC0_w" "Lucille Karma" "https://yt3.googleusercontent.com/4gpEKuAglyHMJj65tmuLq-Br94NjDWV0B5jzo3HmChEt3QETZvag7Fcl1SKOyTsFemiBbtYvxHM=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC3Afj8DuNUu2PV74fJGw-Fw" "Luka Big Pants" "https://yt3.googleusercontent.com/3iaz-urrtQUYnDAnDfFs8HBtLllZEq4O9bZsi_EDvMi4x2WtwZgoED6e3UPR3IAn9V1k1nW1=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCPdaxSov0mgwh77JvjQO2jQ" "Man Carrying Thing" "https://yt3.googleusercontent.com/ytc/AIdro_mf8csHJOlVVH4ZA0BGZdLkxIXMgMEDYtD-KCxSdXuwfOY=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCcnci5vbpLJ-rh_V9yXwawg" "martincitopants" "https://yt3.googleusercontent.com/ytc/AIdro_lI_QS1D1VToF3xOnXjN41QcdEIyxTCJJOMo3Zq939Wxu4=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCZi0oII2ua_I-fEnHdg3U2A" "martincitopantsLIVE" "https://yt3.googleusercontent.com/ytc/AIdro_l11yQO33rxQetZUIxU5kHT7l8m4g1O7FyMzf3-ZxC_Cg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC8dVW9u_aNeGVl1WQnNh6yg" "Matt & Justus" "https://yt3.googleusercontent.com/np40bMwYwcTYWhNH3UvXN0yFMYTzReVlL9XstvloE8CT0RovYRpzWraTx3x1MN884OGeMfZH=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC7YOGHUfC1Tb6E4pudI9STA" "Mental Outlaw" "https://yt3.googleusercontent.com/ytc/AIdro_n6dUcc6YbkWa540dbaWzbLi44bq0h-hGNEop2BhOQ6uHY=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCeYvzUfpNSGnzasUjNKIA_w" "Mike Clum" "https://yt3.googleusercontent.com/qa1Sa2VAhJwINnZ-1SF566Iq4m-LNX3ld3vU_0mzkfdKQfadnwZp7Sc3Hm-jsppj-AMXSMz0JnA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UClUc_jq1BuEczLm0asOeNcw" "Mirabeau Studios" "https://yt3.googleusercontent.com/7FjanwnYSPcHB38aaR8Fkij9JsdWA5URDOzbcsEPakinRDpnAnVigN1waZorX7xtLV2O1x5JEw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCEpHkpv4_CgZIEadjjOv4jA" "Misfit Minds" "https://yt3.googleusercontent.com/DRDObiTHPNhdiqM-idlKhbtOej-XPVcm9FDxFMfGYNntBF3wLfpegKskJ_9C0KAOP8SRdXjowQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC84PVGjO0Q5rgzKXM5aAtvQ" "MitchManix" "https://yt3.googleusercontent.com/zmwyA-kT7iPSRF6R0bRbmGdmBw_b4TH0GGhqYJTZDRjh0nQ7d3_bSJf7WmVek808hqM-LbNoOA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCr1kbyiJzl-x5YYDxhYJuPw" "MoreCaseOh" "https://yt3.googleusercontent.com/SrEBTo8OrYLgv-uQtj05EnOwKZMH1-6K1ZTFzVkng-muhs8VISE9i8GqGkJcx-2KVh31JL418A=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCEQ7KR9enYdQsB6kcMnw0NA" "Mortismal Gaming" "https://yt3.googleusercontent.com/ytc/AIdro_n4ZPhOeF8KQ0OPuzkUdjTlnveQk9FPX0cxELz_bo6Dlrs=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCSdma21fnJzgmPodhC9SJ3g" "NakeyJakey" "https://yt3.googleusercontent.com/9NnqCwNtNncyW1oJnAgdK58p4NC6MaSLe8bMmBtuw0p4Kzl3hkRp00Ckd1xaK6GBID9iKe3Oqg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCiZk_rAHUPJSWwNSAGgV90g" "natedoggbruh" "https://yt3.googleusercontent.com/FlGU89-FaCaMbHN3_yhPfxc2TkfgO4Q1_34rLBc2C9W5TTIEVEGsFXUIhXeD9fLj9ZByEWJwDQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCXEKwWflysXu312NmIP_dlw" "NERDULT" "https://yt3.googleusercontent.com/OtRJWkKUE4u6uwgG1BFAY72QicN25CParSGZKkAdLGbg5yM_U8sFZDF5_gzIhJ--5t1E11w-Lg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCxaaULLk6UCnRl5VKRc7G0A" "No Text To Speech" "https://yt3.googleusercontent.com/Xi5LgenvgPeaKTrJXRkjpX4uEwS-wvjt5ibhFpyj6TcYNKrAc79HHPx0Qe6LydpiPlb7v90eeQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCYlG2eHhMFUtts34csJoONQ" "No_Tables" "https://yt3.googleusercontent.com/D39KV1h2PGPi93a9Z6rowe3bGX5M_jtaaGa-Ia7y8cJnyrkvbetcB0KhIOz4fpeu4WRYs2Gm=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCVYz-US5ya2gdSdrrrVEY5w" "NoEvDia" "https://yt3.googleusercontent.com/ytc/AIdro_kURGPYaN4i3eu0fHzRFR7ftzHMhYxDUzXzsT0tyQRzGA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCEmRB6NQH8u6zdFvcWGXsIw" "Nycro" "https://yt3.googleusercontent.com/ytc/AIdro_lSjm6Cv0J7AEHCy20WVBnC4KC62jhB8oEhARvy2Pp9AkY=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCYaYZQE2pymOZ0k3iaRdgcw" "OdiumNostrum" "https://yt3.googleusercontent.com/ytc/AIdro_m7iK28notJ5N-fOa5QErGXm8qpxFAYIoUbiEGxdIGzSA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCEF1bP6o_oFxLLZGZB_SRNw" "OkSynoh" "https://yt3.googleusercontent.com/fRJKUZHgSfqq8P_b3qXQ-RyQldxa2vYjlpzfUEl_3IbNd36Ep4VE9UswJDcUoDiBzMA-tLK_eQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCcv_d_n6xibI7YYeXDEX9mg" "Ola Englund 2" "https://yt3.googleusercontent.com/7s5gFQcA9beQPRxsoAildeW1Sqy-JljZu02ZFH2AR61VvxZj1RlzvtfPDECfTiJKSxXF7q4WzRM=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC6Mjg5R5QOJYjrio1JmP8Fg" "oompaville" "https://yt3.googleusercontent.com/vg0FrDfJrtOgrXRW7g0jxDTOvgZ_tYIuNySIs5upXiUe8Wu6HFB01eyPkqGSbYmoVQhP9pFcFQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCS1WNeajP1iZT-A5PPCXuZg" "P1nero" "https://yt3.googleusercontent.com/bAttwDM9SwnqbZBFoI05Rs6zHu2JDQ03eGMp7aDSLBj5RULPGS91_YEBoPi0OcRuKVawDRmK=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCA7X5unt1JrIiVReQDUbl_A" "Path of Exile" "https://yt3.googleusercontent.com/WgBOlwF86_fOwcnPZEaVUtviC5w8cCZcL-j7tNH-cahbXkzxZRjl5dD8oHpLO4dIxeP9wbUR=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCJyjyHhZTXVLKqbS_WCFIFg" "Peeb" "https://yt3.googleusercontent.com/FRYvyA8XW1AJyeOyiR7RgpYAzMXxwPwgosG3eqkWFD48fbIZqw3rgXh2FsMpsSDIpdZtZRpy=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCgv2_w0HveLN_JgFGTqwmTw" "Pohx" "https://yt3.googleusercontent.com/TsBNUfnNs6kQ09MN6ebtIHSpubHf2144HzkvT9VK3GGFeB87eTuqP-0TfdxGpmV2YxKX0xGKPg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UChXUVpagGMeq_AbBkog58hg" "Prox Chat" "https://yt3.googleusercontent.com/mZ-JfiS7ms41jw4_INfQzj_GNvo2g2pR0uPZjizSOpS3eYIyUs_n0wXDUr7mQ34eq6faAgpMGQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC8nLGHIUs-Ker0rMulvSBhQ" "ProximityChat" "https://yt3.googleusercontent.com/EQaC7yL3NMJH-KnBrjlydKwHFYEyWDySzDIdkrTjVvzZsb9T5x3X6DImjypiFWqxoLgTN42Jrw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC7WSom2KTVSX9jyBBWF6Stw" "RadicalFishGames" "https://yt3.googleusercontent.com/ytc/AIdro_la3iOIV4Wq4oDlGExdu7tpZiBvyZElxeLwU_YnDat2IQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC6gvWsFgrOKX28ZrVCjjYJw" "RaizQT" "https://yt3.googleusercontent.com/KiWMoNy2SNJwkwNJ4mmKAVvLLqTNei1eD1ozd_jMfovwWIgDpDjBBGv20_DGLZm1B-42Kri1Xg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCdOnAU7RhWpjiQmy-HNkCvg" "RektbyProtoss" "https://yt3.googleusercontent.com/ytc/AIdro_k06vx5D6QH1t6C5NISO11R_E-74W6RpIYPg0Yx-Y2Uq4A=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCjdgz_dVC_V-74m_DbvuPEA" "Renne" "https://yt3.googleusercontent.com/dZ16ufTUWaSgBnJQXqj8gY5hsVIaWc7mTEczLBBRmaW6atSXJIee2smXO_-jD-LiRRCSgOAS8A=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCWLHMlyCAhFK_nZqri-qqeQ" "Richard Grimm" "https://yt3.googleusercontent.com/I7bXt_tOFibZFCvQ-s5uUrHK6TNa9HWNbqv2FiV--7oZ4nLI6aUGnU_BDdv2lJYJdb2OMmzpRmQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCOH3QdgesKmo5JXup5jBpnw" "RiverV" "https://yt3.googleusercontent.com/ytc/AIdro_nKC2IeRw17RjrF5cFXxAtBAxvsC31-EKj9CGSlEqNHUiQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCqweW5IIPrMeZ1o_mMc4RNg" "Royal Moon " "https://yt3.googleusercontent.com/7PHKr26pxD0aRGHMNHMd3i7U6MOCgQFOY97SiBT84hrSQGzMa75nw4EJKFQWRNimQhMtgKj2ztg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCy9L0ITuHozyqAxW26KPvKg" "Rurikhan" "https://yt3.googleusercontent.com/qjpT8qAkN4dZnH6mrwXGn-nmndxOf2RZqBpjZBCSvDMIKz7_8UXam46GGGfSFY_PMpDz-rD1Hw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCUP5UhD6cMfpN4vxW3FYJLQ" "Sam Bent" "https://yt3.googleusercontent.com/Y13SlAFx0dn5pkLi6wGIFxZ56iC017bH1nTLxYmJIyT4InWzHo2XVbDNuiAGKKXpym3L6OwzOg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCGUHXiYaayAaBowPgOjMRVg" "Sampsa" "https://yt3.googleusercontent.com/ytc/AIdro_l51IkXRfmVRtMQd6kYkv547dtvXWJrajg4xGL0uVTaGw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC5TaZWeRgdN7klKM60Hj6rQ" "Season of Mist" "https://yt3.googleusercontent.com/MiHhcRqi19Iq4M5LRpJtqYU2sarOXS8LpIiKr-gR2Ib2CAqqzDdBdtJhDdk6ZUK2-O73qUtYeg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCuobtuGxJny9V5lX5a1ieuw" "Sergeant Steve" "https://yt3.googleusercontent.com/_JaNRZcIQT0Kh68nCdoU9qH45xPDkrw9wyeRxQ8fN9v1IoD15I-aVlBCAr_XoGWT8ogH58KA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC3tw4ZlRfkTkQ_r51RqG9aA" "Shadow Mantra Steve" "https://yt3.googleusercontent.com/ytc/AIdro_nxbxgDbF6x6nhNf32QkZgnz896sqdL3p3OprbXA4GEMyo=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCkoujZQZatbqy4KGcgjpVxQ" "Shawn Ryan Show" "https://yt3.googleusercontent.com/Q4QU_fme2fF3UHscjdJcS7_GvyRHN7JFeZqt70KfbwCH3vYTBcQGnicQmWryd6zztyzSq9T37w=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCOdeQk4PK3vC7XGkZgr7JAQ" "SmugSlav" "https://yt3.googleusercontent.com/S8yHLC1yyU_Xv0CEOoTmJ2-VtKTX7zoI5TuNnOj2s1ct82_Aa4ijuEDtVGmGJxU1RUbl12PJGw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCifRgVk-GEo1_vvf8x53t6A" "Soup" "https://yt3.googleusercontent.com/ytc/AIdro_nl_M75_ug0WYCElVcUgcMWLgnE5O9KzxisdSXEWsJLVrk=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCD6VugMZKRhSyzWEWA9W2fg" "SsethTzeentach" "https://yt3.googleusercontent.com/ytc/AIdro_mXTTQsKU9iBZi4PNaOSXTnnJy-OOwhBARSnfx4DesbyLw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCP0_k4INXrwPS6HhIyYqsTg" "Steven He" "https://yt3.googleusercontent.com/U_MyXuN0wLO7V8izDMdyWkshweE-no-AGb4qK9pfbF3hkWmxmG2JBfurkDQp-tpV05mmDFla=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCPVrjrtyssy19hwxsItXRCw" "Storn " "https://yt3.googleusercontent.com/8pQQ7CZVGa_iSG-dlmhwy4UUEdI6QY-Sr662pxaFnN-qSn18zj4MU8LYbthnVbQ_6WMDW_W5rA=s160-c-k-c0x00ffffff-no-rj")
    (sub "UCopDaG5xA51mvgtv1Jzq-VA" "Sujikan" "https://yt3.googleusercontent.com/ytc/AIdro_lkHHHoMlA1P28JnSYLnhJ1Rw9lcsDt5ij-9h6Y-W2MT54=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCoplJSyTWXGKgMIu0KvwhkQ" "SUPAH" "https://yt3.googleusercontent.com/MMcH5MqPBO5CzRvTNLeKjHOghsjMgjY6pqMVMCHbcJaBuYJl3FlctRmMKvK3tuMWHZifpoACEg=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCKyIN3WgOtdp-35rpgbFINA" "Taylor Danley" "https://yt3.googleusercontent.com/ytc/AIdro_l8vKMkd7fgLfOdAih1lb6Fu_3tW9ahcFQ73aw88YNDthw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCs6KfncB4OV6Vug4o_bzijg" "Techlore" "https://yt3.googleusercontent.com/9Ovy87xCh2rwb8orKSW1vbiQzgztPpLZW4lN16Wp9eDXzlERdQwind5qZpMNVZOcXP0bkW4pWQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCPnSoX7NkOBcOX0Gfw_yjAw" "Tectone" "https://yt3.ggpht.com/5rw8sIhFpVH8DrVIvLThKGc_29yJu1r4JsBy_akPoMYRkANhH3tUmj1JjVv-dZBmyIMAaD4dDA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCgOU3lzWDgTP77TzpzvvcPQ" "Terrastorian" "https://yt3.googleusercontent.com/qSn15r_t1Lr2Z0A1kOlCpwF3tkmUEYjtXKoEBE9rOdkB4wH11GumP0KZXBFCn_pYJSlv3qpR=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCqUiYDmHUhzWlfRLIh5UndQ" "thatTomson" "https://yt3.googleusercontent.com/p_-wbUao5PUwwSGhB78_iQGyM7zvLzUtvkCXvd2fbmN1djfjIV-VuNLFrdD2Bnjr21z7LrROR64=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCgo1RgtW6Q5MQ7dtmd_HUzg" "The August Hail" "https://yt3.googleusercontent.com/UXpHqPOB804f8psB9go2gTUS1G82jxzFmR0lQP66mNslW2xgDl18N3Q0XbsJLE3IbnnAOnT1eA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC5UAwBUum7CPN5buc-_N1Fw" "The Linux Experiment" "https://yt3.googleusercontent.com/ytc/AIdro_lAKf-vZLoTI-gZUoP5Y3gbdGd07E4eDHUhTee6aOzDCnU=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCUyeluBRhGPCW4rPe_UvBZQ" "The PrimeTime" "https://yt3.googleusercontent.com/Eu_xR4JfLlrruwj1lrmfDiOpe8GARBs8M0hgQ6NsGhQ0qC8S-po9HEHw1W21sPN2BHO6EHXrSwM=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC3_ig57nX0zLhNwMFdu-t_A" "Thechrisbarnett" "https://yt3.googleusercontent.com/ytc/AIdro_nzK1tDMzi1HqVX9xt27bReANoJuCLneWvvBSeGM8JJT3k=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCPKgIhTC3BdkAwMw6s-GEug" "TheDooo" "https://yt3.googleusercontent.com/ytc/AIdro_kEFaKcnbbVXFO0fXWdmratH9Hx7sLBYE5XEWyAcrl56gI=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCiToMxeQlTpY4WfPv2WGllQ" "TheSuffocater" "https://yt3.googleusercontent.com/pW_7oyukjK1v8LB1fL6by0dmR_bTmK-bNOTfIy6V9-5_Z6N3ZcBQZK2HdPd4H8riYxivkdeu0A=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCpWEeICUoxrhkjTID4j7-tw" "Threefold" "https://yt3.googleusercontent.com/O-VDmo8G8T1h6wXVWYoVBvkReN24QRuonrRYeZZ-sDmeYEd7R75Qwna1mY_KkQSLyb9DFy17kA=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC5CgpWVCeidRpkGGZnsAxfQ" "Verveine" "https://yt3.googleusercontent.com/5WqFFT_z8pAvEkV-RboY_8SpqdEPWErn9-mpKNppeRO1eXrB97ylHDS71pSn9iep32hppX5ysjM=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCsvn_Po0SmunchJYOWpOxMg" "videogamedunkey" "https://yt3.googleusercontent.com/41hm8RIIr1HbZIg7A_M9CvtHvJdRXtEEwz4JdaxWYjuwDntO0Tyag4Qe104nIxaSnnybsUdnOQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC_zBdZ0_H_jn41FDRG7q4Tw" "Vimjoyer" "https://yt3.googleusercontent.com/OFY2sEROEaNlDPyvkWZuI1lqNJEPk0hwk5Yy6Gxr639wzeZGPHzGkuDHDIKVPh9Q1T0oED6G=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCchBatdUMZoMfJ3rIzgV84g" "Viva La Dirt League" "https://yt3.googleusercontent.com/ytc/AIdro_kTqsz6Fd075zkLMJ5cAoGaC9DEwOmKqui5U3xp0Zb_NZY=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC28n0tlcNSa1iPe5mettocg" "voidzilla" "https://yt3.googleusercontent.com/FaXFjFDVM8EECqYNXjsrjPlBSLPaV6Kfll44hCm8VtqifulHKSp7XmbsSeUfTDYWRtC_Ul_c=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCZIuYUzkmEXgSSXzReOmeLw" "WestJett" "https://yt3.googleusercontent.com/ytc/AIdro_mUJftxEivgLVKLwiD197P7lWpzEaOz2xdxyFjdLL6I2d4=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCDAUhy3xxELJ5k6V2x2TZZA" "Wicked Wizard" "https://yt3.googleusercontent.com/ytc/AIdro_l3VO_uRb6mfZnvGeOk59i0gorPhvAcpLrLjmVpdWLNPQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC-NfY72l3Tn-c2qg0iHDUlQ" "WickedWiz" "https://yt3.googleusercontent.com/WFTpu99fvK31-Q5cUtDzz1QajbjbJ1PEXidIbi5p7PeEYUNV7RlAiOM0Fyz8GUx0PQdBzG-D=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCfJxmjbygyA5KEdzzZv6Pbw" "Wizards with Guns" "https://yt3.googleusercontent.com/ytc/AIdro_lOAVmHPJbYXnm2fsYivYSfJNNV7YAw-TxnufASQ1RR0rY=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC0ZGpaIfJX8xJ_gHI9Zqaww" "Wyattxhim" "https://yt3.googleusercontent.com/IRHpwJUMNaCcUy4PKwoKw_bw-RaZAPto0C0pQT0COn8ZX7GZIfiuUf9uqSGATCEzLwg-wWuVpQ=s176-c-k-c0x00ffffff-no-rj")
    (sub "UCKcOaIOHUttWdSUx15WQjJw" "Yardis" "https://yt3.googleusercontent.com/AuhG6bj7tv0L8liEaHCpXfOh6gryUZcRoOzC89tKr8imjEM1Yr3FtY83rnEeiwcmBcFgBTk6Dw=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC4mLMb49hqk4y9lVFtfanlg" "ZiggyD Gaming" "https://yt3.googleusercontent.com/ytc/AIdro_n6a4BSaTQGLIHAknLe6P6dPzWHz6u3PYpMvwa6FoIx0w=s176-c-k-c0x00ffffff-no-rj")
    (sub "UC70Q84V4Cbf-wFWprkoW8Eg" "zimery" "https://yt3.googleusercontent.com/TLLnVtdkRbhtWa0o6xL1wiHyXXi8J94-qM6oHPb0Rdgqw87aO_-QlTjwHWXDMDGNoYPRA5klyFE=s176-c-k-c0x00ffffff-no-rj")
  ];

  profile = {
    _id = "allChannels";
    name = "All Channels";
    bgColor = "#268bd2";
    textColor = "#FFFFFF";
    inherit subscriptions;
  };

  profilesDb = pkgs.writeText "hm_profiles.db" (builtins.toJSON profile + "\n");
in {
  #--------------------------------------------------------------------#
  #-- Seed
  #--------------------------------------------------------------------#
  # Kept in the config dir as a restore point; copy it over profiles.db by
  # hand to reset subscriptions to the declared list.
  xdg.configFile."FreeTube/hm_profiles.db".source = profilesDb;

  home.activation.freetubeSeedProfiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
    db="${config.xdg.configHome}/FreeTube/profiles.db"
    if [[ ! -e "$db" ]]; then
      run install -Dm644 $VERBOSE_ARG '${profilesDb}' "$db"
    fi
  '';
}
