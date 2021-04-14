---Parse query to create as insert

select distinct 'Insert into S_IP_RANGE (RANGE_ID, USER_ID, START_IP, STOP_IP) Values
((select MAX(RANGE_ID) + 1 from S_IP_RANGE),' As "column1", us.USER_ID ,',''199.247.42.1'',' AS
"column2",'''199.247.43.254''' as "column3", ');' as "Last Column" from S_IW_CUST_ACCT CA
inner join S_WCM_USER_CUST_ACCT UCA on CA.CUST_ACCT_ID = UCA.CUST_ACCT_ID
inner join portal.users us on us.user_name = UCA.USER_ID AND us.ACTV_USER_IND IS NULL and us.chk_ip_ind= 'Y'
where CA.CUST_CHN_ID = '676';


--------------------------------------------------------------------------------------------

-- insert if not exists
insert into USERS (USER_ID,ACCOUNT_ID,DOWNLOAD_DATA,HDR_FUNC,ORD_NUM)
select 'TEST_USERS','908976','Y','N'
from dual
where not exists(select *
from S_USER_CUST_ACCT
where (USER_ID ='TEST_USERS' and CUST_ACCT_ID ='908976'));


-- Fetch records from last two years

elect idb.P_CREATIONDATE,enu.CODE, idba.P_IDBACCOUNTNAME from appe.IDBDOCUMENT idb
left join appe.ENUMERATIONVALUES7 enu on enu.PK = idb.P_STATUS
left join appe.IDBACCOUNT idba on idb.P_IDBACCOUNT = idba.pk
left join appe.USERGROUPS usg on usg.PK = idba.P_ORDERINGACCOUNT
where
usg.P_UID = '383813'
and idb.P_CREATIONDATE > trunc(sysdate,'YY') - INTERVAL '2' YEAR;


-- Bulk update with cursor exmaple

SET SERVEROUTPUT ON SIZE UNLIMITED;
DECLARE
    CURSOR order_cursor IS
        SELECT DISTINCT
               (CON.P_DRGEOEORDERID)     AS DRGEOEORDERID,
               ord.pk,
               ORD.P_CODE                AS HMC_CODE
          FROM appe.ORDERS  ORD
               INNER JOIN appe.CONSIGNMENTS CON
                   ON CON.P_DRGEOEORDERID = ORD.P_DRGEOEORDERID
         WHERE     CON.P_DRGEOEORDERID IN
                       (SELECT
ORD.P_DRGEOEORDERID
FROM appe.ORDERS ORD
INNER JOIN appe.USERGROUPS USG ON USG.PK = ORD.P_UNIT
WHERE ORD.P_STATUS = 'SUBMITTED'
AND ORD.P_PLACEDON >= SYSDATE - INTERVAL '7' DAY
AND trunc(ORD.P_PLACEDON) < trunc(SYSDATE)
ORDER BY ORD.P_PLACEDON DESC;))
               AND CON.P_ACKTYPECODE = 'I';

    v_drg     appe.consignments.P_DRGEOEORDERID%TYPE;
    v_order   appe.orders.pk%TYPE;
    v_code    appe.orders.p_code%TYPE;
BEGIN
    OPEN order_cursor;

    LOOP
        FETCH order_cursor INTO v_drg, v_order, v_code;

        EXIT WHEN order_cursor%NOTFOUND;

      /*  UPDATE appe.consignments
           SET P_order = v_order, P_STATUS = NULL
         WHERE P_DRGEOEORDERID = v_drg;*/

        DBMS_OUTPUT.PUT_LINE (
            'Consignment DRG ' || v_drg || :new.col || 'Order Assigned ' || v_order );

        UPDATE appe.CONSIGNMENTENTRIES CONE
           SET CONE.P_ORDERENTRY =
                   (SELECT ORDE.PK
                      FROM appe.ORDERENTRIES ORDE
                     WHERE     CONE.P_ORDERITEM = ORDE.P_PRODUCT
                           AND ORDE.P_ORDER = (SELECT PK
                                                 FROM appe.ORDERS
                                                WHERE P_CODE = v_code))
         WHERE CONE.P_CONSIGNMENT IN
                   (SELECT PK
                      FROM appe.CONSIGNMENTS
                     WHERE     P_ACKTYPECODE = 'I'
                           AND P_ORDER = (SELECT PK
                                            FROM appe.ORDERS
                                           WHERE P_CODE = v_code));

        DBMS_OUTPUT.PUT_LINE (
            'Order ' || v_code || :new.col || ' Consignment Relation Done');
    END LOOP;

    CLOSE order_cursor;
END;





-- Long query session
SELECT *
  FROM (  SELECT opname,
                 start_time,
                 target,
                 sofar,
                 totalwork,
                 units,
                 elapsed_seconds,
                 MESSAGE
            FROM v$session_longops
        ORDER BY start_time DESC)
 WHERE ROWNUM <= 1;


 --- All Main lication groups Portal

 SELECT distinct US.USER_NAME, us.EMAIL_ADDRESS,
                (SELECT CASE COUNT (UGM.GROUP_UID)
                            WHEN 0 THEN 'N'
                            ELSE 'Y'
                        END
                   FROM PORTAL.USERGROUPMEMBERSHIP UGM
                  WHERE     UGM.USER_UID = US.UNIQUE_ID
                        AND UGM.GROUP_UID IN
                                (SELECT UG.UNIQUE_ID
                                   FROM PORTAL.USERGROUPS UG
                                  WHERE UG.DESCRIPTION =
                                        'A user Group of MCAP 2.0'))    AS "AP Access",
                                        (SELECT CASE COUNT (UGM.GROUP_UID)
                            WHEN 0 THEN 'N'
                            ELSE 'Y'
                        END
                   FROM PORTAL.USERGROUPMEMBERSHIP UGM
                  WHERE     UGM.USER_UID = US.UNIQUE_ID
                        AND UGM.GROUP_UID IN
                                (SELECT UG.UNIQUE_ID
                                   FROM PORTAL.USERGROUPS UG
                                  WHERE UG.DESCRIPTION =
                                        'Catalog group'))    AS "Catalog",
                                        (SELECT CASE COUNT (UGM.GROUP_UID)
                            WHEN 0 THEN 'N'
                            ELSE 'Y'
                        END
                   FROM PORTAL.USERGROUPMEMBERSHIP UGM
                  WHERE     UGM.USER_UID = US.UNIQUE_ID
                        AND UGM.GROUP_UID IN
                                (SELECT UG.UNIQUE_ID
                                   FROM PORTAL.USERGROUPS UG
                                  WHERE UG.NAME =
                                        'IDB'))    AS "IDB",
                                          (SELECT CASE COUNT (UGM.GROUP_UID)
                            WHEN 0 THEN 'N'
                            ELSE 'Y'
                        END
                   FROM PORTAL.USERGROUPMEMBERSHIP UGM
                  WHERE     UGM.USER_UID = US.UNIQUE_ID
                        AND UGM.GROUP_UID IN
                                (SELECT UG.UNIQUE_ID
                                   FROM PORTAL.USERGROUPS UG
                                  WHERE UG.name =
                                        'Orders'))    AS "Orders",
                                                  (SELECT CASE COUNT (UGM.GROUP_UID)
                            WHEN 0 THEN 'N'
                            ELSE 'Y'
                        END
                   FROM PORTAL.USERGROUPMEMBERSHIP UGM
                  WHERE     UGM.USER_UID = US.UNIQUE_ID
                        AND UGM.GROUP_UID IN
                                (SELECT UG.UNIQUE_ID
                                   FROM PORTAL.USERGROUPS UG
                                  WHERE UG.name =
                                        'Reports And Analysis 6.0'))    AS "Report and Analysis"
  FROM PORTAL.USERS  US
       INNER JOIN PORTAL.USERGROUPMEMBERSHIP UGM
           ON US.UNIQUE_ID = UGM.USER_UID
       INNER JOIN PORTAL.USERGROUPS UG ON UGM.GROUP_UID = UG.UNIQUE_ID
       INNER JOIN S_USER_ACCOUNT ua ON ua.USER_ID = us.USER_NAME
       INNER JOIN S_IW_CUST_ACCT act
           ON ua.CUST_ACCT_ID = act.CUST_ACCT_ID AND act.NATL_GRP_CD = '0160'
 WHERE act.NATL_SUB_GRP_CD = '000999' AND act.CUST_RGN_NUM = '000064'
       AND us.ACTV_USER_IND IS NULL/*Null means active user*/;



-- Auto Send Stuck - last 24 hours
SELECT DISTINCT
         car.P_code AS "Cart ID",
         enu.code AS "Status",
         ug.P_UID AS "Account Number",
         car.P_PURCHASEORDERNUMBER AS "purchase Order Number",
         to_timestamp(tr.P_ACTIVATIONTIME)     AS "Activation Time",
         SYSTIMESTAMP - to_timestamp(tr.P_ACTIVATIONTIME) AS "Stuck Time"
    FROM appe.CARTS car
         INNER JOIN appe.MCKTRIGGER tr ON car.P_ASSUBMITDATE = tr.pk
         INNER JOIN appe.USERGROUPS ug ON ug.pk = car.p_unit
         INNER JOIN appe.CARTENTRIES cae ON cae.p_order = car.pk
         INNER JOIN appe.ENUMERATIONVALUES7 enu ON enu.pk = car.p_status
   WHERE     enu.code IN ('OPEN', 'PENDING')
         AND car.P_LOCKEDBYAUTOSEND <> 1
         AND car.P_LOCKEDFORSUBMISSION <> 1
         AND TO_TIMESTAMP (tr.P_ACTIVATIONTIME) >=
             SYSTIMESTAMP - INTERVAL '1' DAY
         AND TO_TIMESTAMP(tr.P_ACTIVATIONTIME)< SYSTIMESTAMP
         AND (SELECT COUNT (*)
                FROM appe.B2BUNIT2ACCPERMREL rel
                     INNER JOIN appe.ABSTRACTPERMISSIONCODE code
                         ON code.pk = rel.TARGETPK
                     INNER JOIN appe.ENUMERATIONVALUES7 enu2
                         ON enu2.pk = code.P_CODE
               WHERE     rel.SOURCEPK = ug.pk
                     AND enu2.code IN
                             ('ACCOUNT_EXTERNAL_REVIEW_ENABLED',
                              'ACCOUNT_ORDER_CREDIT_CARD_ENABLED')) =
             0
ORDER BY 3 DESC;


--------------------- portal Report ------------
vignette@ddcdxp14:/home/vignette>cat /vignette/s/support/biweekly/quaterlyuseridreport/qualterlyuserid.sql
WHENEVER SQLERROR EXIT SQL.SQLCODE;
--SET NEWPAGE NONE
--SET SPACE 0
SET LINESIZE 500
SET TRIMSPOOL ON
SET PAGESIZE 15000
--SET ECHO OFF
--SET FEEDBACK OFF
--SET VERIFY OFF
SET HEADING OFF
--SET COLSEP ','
--SET TERMOUT OFF
--SET UNDERLINE OFF
--SET ARRAYSIZE 500
--COLUMN USER_ID HEADING 'USER_ID' FORMAT A15
--COLUMN ACTION_ID HEADING 'ACTION_ID' FORMAT 99999
--COLUMN TIMESTAMP HEADING 'TIMESTAMP' FORMAT A50
--COLUMN USERHOST HEADING 'USERHOST' FORMAT A30
--COLUMN TARGET_USER_ID HEADING 'TARGET_USER_ID' FORMAT A15
--COLUMN MODULE_ID HEADING 'MODULE_ID' FORMAT 99999
--COLUMN FIELD_ID HEADING 'FIELD_ID' FORMAT A15
--COLUMN OLD_VALUE HEADING 'OLD_VALUE' FORMAT A50
--COLUMN NEW_VALUE HEADING 'NEW_VALUE' FORMAT A50
--COLUMN ID HEADING 'ID' FORMAT 9999999

spool &1/QUARTERLY_USER_ID_REPORT_0350.csv
/* Formatted on 3/27/2014 2:48:11 PM (QP5 v5.240.12305.39446) */
  SELECT /*+ leading(SUCA PU SICA SDCA) USE_HASH(SUCA PU) */
        DISTINCT
         sica.CUST_CHN_ID ,
         sica.NATL_GRP_CD ,
         sica.NATL_SUB_GRP_CD ,
         sica.CUST_RGN_NUM ,
         sica.CUST_DSTRCT_NUM ,
         sica.cust_acct_id ,
         sica.CUST_ACCT_NAM ,
         TRIM (UPPER (pu.user_name)),
         pu.first_name ,
         pu.last_name ,
         pu.email_address ,
         pu.MOBILE_PHONE ,
         PU.DAY_PHONE ,
         PU.EMPLOYER ,
         DECODE (pu.INTRNL_EXTRNL_CD, 'I', 'Internal', 'External')
            ,
         DECODE (pu.user_id,
                 NULL, 'N/A',
                 DECODE (pu.ACTV_USER_IND, 'I', 'InActive', 'Active'))
            ,
         DECODE (
            PU.SGMNT_ROLE_CD,
            NULL, '',
               '['
            || PU.SGMNT_ROLE_CD
            || '] '
            || WS.SEG_NAM
            || ' -> '
            || WSR.SEG_ROLE_NAM)
            ,
         axinfo.LAST_LOGIN ,
         sup.prfl_nam ,
         MAX (DECODE (suf.func_cd, '13', 'Y', 'N')) ,
         MAX (DECODE (suf.func_cd, '36', 'Y', 'N')) ,
         MAX (DECODE (suf.func_cd, '16', 'Y', 'N')) ,
         MAX (DECODE (suf.func_cd, '59', 'Y', 'N')) ,
         MAX (DECODE (suf.func_cd, '53', 'Y', 'N')) ,
        MAX (DECODE (suf.func_cd, '11', 'Y', 'N')) ,
         MAX (
            DECODE (
               vg.unique_id,
               'epi:usergroup.standard;e6ab793b6b342d60f4f151435740d0a0', 'True',
               ' '))
            ,
         MAX (
            DECODE (
               vg.unique_id,
               'epi:usergroup.standard;473c34b6213cd7e247a9b4105740d0a0', 'True',
               ' '))
            ,
         MAX (
            DECODE (
               vg.unique_id,
               'epi:usergroup.standard;05235441d7b9e3d0f4f151435740d0a0', 'True',
               ' '))
            ,
         MAX (
            DECODE (
               vg.unique_id,
               'epi:usergroup.standard;de48e1496a076af7d64598865740d0a0', 'True',
               ' '))
            ,
         MAX (
            DECODE (
               vg.unique_id,
               'epi:usergroup.standard;92d1902cbeeba382da30ab30234470a0', 'True',
               ' '))
            ,
         MAX (
            DECODE (
               vg.unique_id,
               'epi:usergroup.standard;de1e8bd10630986051741db0783470a0', 'True',
               ' '))
            ,
         MAX (
            DECODE (
               vg.unique_id,
               'epi:usergroup.standard;201095b9d6260482da30ab30234470a0', 'True',
               ' '))
               FROM s_wcm_cust_acct sica
         INNER JOIN
         s_wcm_user_cust_acct suca
            ON (    TRIM (suca.cust_acct_id) = TRIM (sica.cust_acct_id)
                AND sica.NATL_GRP_CD IN ('0350', '0657', '0666'))
         INNER JOIN S_WCM_USERS PU
            ON (LOWER (TRIM (SUCA.USER_ID)) = LOWER (TRIM (PU.USER_NAME)))
         INNER JOIN S_WCM_USERGROUPMEMBERSHIP vgm
            ON (PU.unique_id = vgm.user_uid)
         INNER JOIN S_WCM_USERGROUPS vg ON (vgm.group_uid = vg.unique_id)
         LEFT OUTER JOIN
         S_WCM_SEG_ROLE WSR
            ON (PU.SGMNT_CD = WSR.SEG_ID AND WSR.SEG_ROLE_ID = PU.SGMNT_ROLE_CD)
         LEFT OUTER JOIN S_WCM_SEG WS ON (WSR.SEG_ID = WS.SEG_ID)
         LEFT OUTER JOIN S_WCM_AUXILIARYUSERINFO_S axinfo ON (PU.unique_id = axinfo.login)
         LEFT OUTER JOIN (select * from S_USER_PRFL@LINK_525Z2) sup
            ON UPPER (TRIM (suca.user_id)) = UPPER (TRIM (sup.user_id))
         LEFT OUTER JOIN
          (select * from s_user_func@LINK_525Z2) SUF
            ON (    TRIM (SUF.user_id) = TRIM (UPPER (pu.user_name))
                AND suf.func_cd IN ('13', '36', '16','59','53','11'))
GROUP BY sica.cust_acct_id,
         sica.CUST_ACCT_NAM,
         sica.CUST_CHN_ID,
         sica.NATL_GRP_CD,
         sica.NATL_SUB_GRP_CD,
         sica.CUST_RGN_NUM,
         sica.CUST_DSTRCT_NUM,
         TRIM (UPPER (pu.user_name)),
         pu.first_name,
         pu.last_name,
         pu.email_address,
         pu.MOBILE_PHONE,
         PU.DAY_PHONE,
         PU.EMPLOYER,
         DECODE (pu.INTRNL_EXTRNL_CD, 'I', 'Internal', 'External'),
         DECODE (pu.user_id,
                 NULL, 'N/A',
                 DECODE (pu.ACTV_USER_IND, 'I', 'InActive', 'Active')),
         PU.SGMNT_ROLE_CD,
         WS.SEG_NAM,
         WSR.SEG_ROLE_NAM,
         axinfo.LAST_LOGIN,
         sup.prfl_nam;

--------------------------------------------------------------------------------
