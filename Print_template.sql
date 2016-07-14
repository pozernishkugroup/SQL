select ao.ID
, shc.name AS company_code
, nra.networkvaluenames
, ao.ADORDERNUMBER
, to_char(ao.CREATEDATE, 'MM/dd/yyyy') as CREATEDATE
, c.NAME2 || ' ' || c.NAME1 as NAME
, c.CAMPANYNAME2 as COMPANY_NAME 
, to_char(ar.EFFECTIVEDATE, 'MM/dd/yyyy') as EFFECTIVEDATE
, ar.AMOUNT -- , ar.AMOUNTPAID 
, aop.NAME as PLACEMENT
, prod.NAME as PRODUCT 
, to_char(aac.ADWIDTH/1440,'FM999999.99') as WIDTH
, to_char(aac.ADDEPTH/1440, 'FM999999.99') as DEPTH
, aac.NUMCOLUMNS 
, u.USERFNAME || ' ' || u.USERLNAME as SALESREP 
, c.accountnumber 
, l.ADDRESS1, l.ADDRESS2, l.ADDRESS3, l.ADDRESS4, l.CITY, l.state, l.POSTALCODE, l.COUNTRY
, st.STATENAME_A
, rs.SORTTEXT
, to_char(aord.STARTDATE, 'MM/dd/yyyy') as STARTDATE
, to_char(aord.ENDDATE, 'MM/dd/yyyy') as ENDDATE
, aoud.NAME as ADSIZEUNIT
, ap.ISONLINEPRODUCT
, AOORDER.PONUMBER as PurchaseOrder

,( 
select valueid from nravalues where nraid=( 
select id from nra where customerid = c.ACCOUNTID and networkattributeid = (select id from networkattributes where attributename = 'tearsheet' and networkid = (select id from adnetworks where name = 'CUSTOMER')) 
) 
) Tearsheetflag 
from ARTRANSACTIONS ar 
join AOADORDER ao on ar.ORDERID=ao.ID 
join RTCHARGEENTRYELEM rtc on ar.RTCHARGEENTRYELEMID=rtc.ID 
join AOADRUNSCHEDULE rs on rtc.ADRUNSCHEDULEID=rs.ID 

LEFT join AOADRUNDATES aord ON rs.id=aord.ADRUNSCHEDULEID

join AOADCONTENT aac on rtc.ADCONTENTID=aac.ID 
join AOADINFO ai on aac.ADINFOID=ai.ID 
join customer c on ar.CUSTOMERID=c.ACCOUNTID 
join location l on c.accountid = l.customerid 
left join statename st on st.STATEID=c.PRIMARYSTATEID 
join usrusers u on ar.SALESREPID=u.USERID 
join aoplacements aop on rs.PLACEMENTID=aop.ID 
join AOPRODUCTS prod on rs.PRODUCTID=prod.ID 
join AoProductDef ap ON rs.ProductID = ap.ProductID and prod.ID = ap.PRODUCTID
join shcompanies shc ON ap.companyid = shc.id 
INNER JOIN AOORDERCUSTOMERS AOORDER ON rs.ADORDERID = AOORDER.ADORDERID
LEFT join aouserunitdefs aoud ON aac.userunitid = aoud.id 

join nra on nra.id=( 
  select id from nra where orderid = ao.ID and networkattributeid = 
    (select id from networkattributes where attributename = 'salesdesk' and networkid = 
      (select id from adnetworks where name = 'CUSTOMER') 
    ) 
) 

where ao.ADORDERNUMBER=@AdOrderNumber_Param
-- AND ao.CreateDate BETWEEN to_date(@DateStart, 'yyyyMMdd') AND to_date(@DateEnd,'yyyyMMdd')
AND RS.ADORDERID = ao.ID 
AND l.primary=1 
order by ar.EFFECTIVEDATE