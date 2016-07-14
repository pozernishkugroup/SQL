select ao.ID
, ao.ADORDERNUMBER
, ar.AMOUNT
, to_char(ar.EFFECTIVEDATE, 'MM/dd/yyyy') as EFFECTIVEDATE
, rs.SORTTEXT

, dbf_runschedule_startdate(rs.id) RSSTARTDATE
, dbf_runschedule_enddate (rs.id) RSENDDATE

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
,( 
select valueid from nravalues where nraid=( 
select id from nra where customerid = c.ACCOUNTID and networkattributeid = (select id from networkattributes where attributename = 'tearsheet' and networkid = (select id from adnetworks where name = 'CUSTOMER')) 
) 
) Tearsheetflag 
, dbu.BEANTYPE
, bea.NAME BundleSubProduct

FROM ARTRANSACTIONS ar 
join AOADORDER ao on ar.ORDERID=ao.ID
join RTCHARGEENTRYELEM rtc on ar.RTCHARGEENTRYELEMID=rtc.ID
join AOADRUNSCHEDULE rs on rtc.ADRUNSCHEDULEID=rs.ID
LEFT join AOADRUNDATES aord ON rs.id=aord.ADRUNSCHEDULEID 
join customer c on ar.CUSTOMERID=c.ACCOUNTID 
join location l on c.accountid = l.customerid 
left join statename st on st.STATEID=c.PRIMARYSTATEID
join usrusers u on ar.SALESREPID=u.USERID  
join AOPRODUCTS prod on rs.PRODUCTID=prod.ID 
join AoProductDef ap ON rs.ProductID = ap.ProductID and prod.ID = ap.PRODUCTID
join shcompanies shc ON ap.companyid = shc.id 
INNER JOIN AOORDERCUSTOMERS AOORDER ON rs.ADORDERID = AOORDER.ADORDERID
join nra on nra.id=( 
  select id from nra where orderid = ao.ID and networkattributeid = 
    (select id from networkattributes where attributename = 'salesdesk' and networkid = 
      (select id from adnetworks where name = 'CUSTOMER') 
    ) 
) 

JOIN DATABEANUSE dbu ON dbu.RUNSCHEDULEID = rtc.ADRUNSCHEDULEID
JOIN DATABEAN bea ON bea.ROOTID = dbu.ROOTID

WHERE ao.ADORDERNUMBER = @AdOrderNumber_Param
AND (dbu.BEANTYPE = 'localedge_Bundle' OR dbu.BEANTYPE = 'localedge_Product')
-- AND ((dbu.BEANTYPE = 'localedge_Bundle' AND ar.AMOUNT = 0)
-- OR (dbu.BEANTYPE = 'localedge_Product' AND ar.AMOUNT > 0))

AND bea.DELETEDBY IS NULL

AND RS.ADORDERID = ao.ID 
AND l.primary=1
order by ar.EFFECTIVEDATE