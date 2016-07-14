select ao.ID
, ao.ADORDERNUMBER
, dbu.BEANTYPE
, bea.NAME SITE

, dbf_runschedule_startdate(rs.id) RSSTARTDATE
, dbf_runschedule_enddate (rs.id) RSENDDATE

, (SELECT dabn.NAME
FROM DATABEANUSE duse
JOIN DATABEAN dabn ON duse.ROOTID = dabn.ROOTID
WHERE RUNSCHEDULEID = dbu.RUNSCHEDULEID AND BEANTYPE = 'dfp_section') SECT

, ar.AMOUNT
, to_char(ar.EFFECTIVEDATE, 'MM/dd/yyyy') as EFFECTIVEDATE
, CASE 
WHEN SUBSTR(dbf_runschedule_startdate (rs.id), -5) = SUBSTR(dbf_runschedule_enddate (rs.id), -5)
THEN dbf_runschedule_enddate (rs.id)
WHEN SUBSTR(ar.EFFECTIVEDATE, -5) = SUBSTR(dbf_runschedule_enddate (rs.id), -5)
THEN dbf_runschedule_enddate (rs.id)
ELSE ar.billingdate END line_end_date

, rs.SORTTEXT

, (SELECT NETWORKVALUENAMES FROM NRA
WHERE ORDERID = ao.id AND NETWORKATTRIBUTEID = (select id from networkattributes where attributename = 'caption' and networkid = 
      (select id from adnetworks where name = 'ORDER'))) CAPT

, rs.SORTOVERRIDE
, nra.networkvaluenames
, to_char(ao.CREATEDATE, 'MM/dd/yyyy') as CREATEDATE
, to_char(aord.STARTDATE, 'MM/dd/yyyy') as STARTDATE
, to_char(aord.ENDDATE, 'MM/dd/yyyy') as ENDDATE
, c.NAME2 || ' ' || c.NAME1 as NAME
, c.CAMPANYNAME2 as COMPANY_NAME 
, c.accountnumber
, l.ADDRESS1, l.ADDRESS2, l.ADDRESS3, l.ADDRESS4, l.CITY, l.state, l.POSTALCODE, l.COUNTRY
, st.STATENAME_A
, u.USERFNAME || ' ' || u.USERLNAME as SALESREP 
, prod.NAME as PRODUCT 
, ap.ISONLINEPRODUCT
, shc.name AS company_code
, AOORDER.PONUMBER as PurchaseOrder
, aoud.NAME || ' ' || clr.NAME as ADSIZEUNIT
,( 
select valueid from nravalues where nraid=( 
select id from nra where customerid = c.ACCOUNTID and networkattributeid = (select id from networkattributes where attributename = 'tearsheet' and networkid = (select id from adnetworks where name = 'CUSTOMER')) 
) 
) Tearsheetflag 

FROM ARTRANSACTIONS ar 
join AOADORDER ao on ar.ORDERID=ao.ID
join RTCHARGEENTRYELEM rtc on ar.RTCHARGEENTRYELEMID=rtc.ID
join AOADRUNSCHEDULE rs on rtc.ADRUNSCHEDULEID=rs.ID
LEFT join AOADRUNDATES aord ON rs.id=aord.ADRUNSCHEDULEID
join AOADCONTENT aac on rtc.ADCONTENTID=aac.ID
join customer c on ar.CUSTOMERID=c.ACCOUNTID 
join location l on c.accountid = l.customerid 
left join statename st on st.STATEID=c.PRIMARYSTATEID
join usrusers u on ar.SALESREPID=u.USERID 
join AOPRODUCTS prod on rs.PRODUCTID=prod.ID 
join AoProductDef ap ON rs.ProductID = ap.ProductID and prod.ID = ap.PRODUCTID
join shcompanies shc ON ap.companyid = shc.id 
INNER JOIN AOORDERCUSTOMERS AOORDER ON rs.ADORDERID = AOORDER.ADORDERID
LEFT join aouserunitdefs aoud ON aac.userunitid = aoud.id
LEFT JOIN AoColors clr ON clr.ID = aac.COLORTYPEID

JOIN DATABEANUSE dbu ON dbu.RUNSCHEDULEID = rtc.ADRUNSCHEDULEID
JOIN DATABEAN bea ON bea.ROOTID = dbu.ROOTID

join nra on nra.id=( 
  select id from nra where orderid = ao.ID and networkattributeid = 
    (select id from networkattributes where attributename = 'salesdesk' and networkid = 
      (select id from adnetworks where name = 'CUSTOMER') 
    )
)

WHERE ao.ADORDERNUMBER = @AdOrderNumber_Param
AND (dbu.BEANTYPE = 'dfp_site')
AND RS.ADORDERID = ao.ID 
AND l.primary=1
order by ar.EFFECTIVEDATE