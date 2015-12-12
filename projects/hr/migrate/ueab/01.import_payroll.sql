CREATE TABLE QTABLE (
	id						serial primary key,
	QNAME			varchar(50), 
	QDATE			timestamp, 
	QTEXT			text, 
	QWHERE			varchar(120), 
	QWHERE1			varchar(120), 
	QWHERE2			varchar(120), 
	QGROUPBY			text, 
	QORDERBY			text, 
	QUSE			varchar(50), 
	QNUM			varchar(50)
);

CREATE TABLE TRANSTABLE (
	id						serial primary key,
	EMPLOYEEID			integer, 
	EMPLOYEEMONTHID			integer, 
	TRANSDATE			DATE, 
	AMOUNT			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE LOGINLIST (
	id						serial primary key,
	LOGINNAME			varchar(12), 
	FULLNAME			varchar(50), 
	USERPASS			varchar(12), 
	USERLEVEL			integer, 
	LASTLOGIN			timestamp, 
	ISACTIVE			varchar(3)
);

CREATE TABLE JOBS (
	id						serial primary key,
	JOBID			varchar(3), 
	JOBNAME			varchar(50), 
	BASICRATE			FLOAT, 
	ACCOUNTNUMBER			varchar(32), 
	YEARBUDGET			FLOAT, 
	DETAILS			text
);

CREATE TABLE DEPARTMENTS (
	id						serial primary key,
	DEPARTMENTID			integer, 
	DEPARTMENTNAME			varchar(50), 
	ACCOUNTNUMBER			varchar(30), 
	TAXACCOUNT			varchar(30), 
	NHIFACCOUNT			varchar(30), 
	NSSFACCOUNT			varchar(30), 
	RETIREMENTACCOUNT			varchar(30), 
	DETAILS			text, 
	DEPFUNCTION			varchar(50), 
	DEPTPROJECT			varchar(25)
);

CREATE TABLE BANKS (
	id						serial primary key,
	BANKID			integer, 
	BANKNAME			varchar(50), 
	ACCOUNTNUMBER			varchar(50), 
	ISBANKED			varchar(3), 
	NARRATIVE			varchar(120)
);

CREATE TABLE BRANCH (
	id						serial primary key,
	BRANCHID			integer, 
	BRANCHNAME			varchar(50), 
	BRANCH			varchar(50), 
	NARRATIVE			varchar(120)
);

CREATE TABLE DEDUCTIONS (
	id						serial primary key,
	DEDUCTIONID			integer, 
	DEDUCTIONNAME			varchar(50), 
	ACCOUNTNUMBER			varchar(50), 
	TAXEXEMPT			varchar(3), 
	DISPCOLUMN			integer, 
	DETAILS			text, 
	APROJECT			varchar(50), 
	AFUNCTION			varchar(50)
);

CREATE TABLE ALLOWANCES (
	id						serial primary key,
	ALLOWANCEID			integer, 
	ALLOWANCENAME			varchar(50), 
	TAXABLE			varchar(3), 
	DISPCOLUMN			integer, 
	DETAILS			text
);

CREATE TABLE ALLOWANCEACCOUNTS (
	id						serial primary key,
	ALLOWANCEACCOUNTID			integer, 
	ALLOWANCEID			integer, 
	DEPARTMENTID			integer, 
	ACCOUNTNUMBER			varchar(50), 
	NARRATIVE			varchar(120)
);

CREATE TABLE TAXRATES (
	id						serial primary key,
	TAXRATEID			integer, 
	LOWERRANGE			FLOAT, 
	UPPERRANGE			FLOAT, 
	TAXRATE			FLOAT, 
	TAXRELIEF			FLOAT
);

CREATE TABLE NHIFRATES (
	id						serial primary key,
	NHISRATEID			integer, 
	LOWERRANGE			FLOAT, 
	UPPERRANGE			FLOAT, 
	AMOUNT			FLOAT
);

CREATE TABLE NSSFRATES (
	id						serial primary key,
	NSSFRATEID			integer, 
	LOWERRANGE			FLOAT, 
	NSSFRATE			FLOAT
);

CREATE TABLE EMPLOYEES (
	id						serial primary key,
	EMPLOYEEID			integer, 
	DEPARTMENTID			integer, 
	BANKID			integer, 
	BRANCHID			integer, 
	EMPLOYEENAME			varchar(50), 
	ACCOUNTNO			varchar(12), 
	IDNUMBER			varchar(50), 
	NATIONALITY			varchar(50), 
	POST			varchar(50), 
	EDUCATION			varchar(50), 
	WORKERTYPE			varchar(50), 
	BIRTHDATE			timestamp, 
	GRADE			varchar(12), 
	ADDRESS			varchar(25), 
	TOWN			varchar(25), 
	TELEPHONE			varchar(25), 
	MOBILE			varchar(25), 
	BASICSALARY			FLOAT, 
	NSSF			varchar(12), 
	NHIF			varchar(12), 
	PIN			varchar(12), 
	HOUSERATE			FLOAT, 
	ISHOUSED			varchar(3), 
	ISPERMANENT			varchar(3), 
	ISCURRENT			varchar(3), 
	ISNHIF			varchar(3), 
	ISNSSF			varchar(3), 
	CONTRACTPERIOD			integer, 
	PRESERVICE			integer, 
	DATEEMPLOYED			DATE, 
	DATELEFT			DATE, 
	EMPLOYEESEX			varchar(50), 
	MARITALSTATUS			varchar(50), 
	SPOUSENAME			varchar(50), 
	RANGE			varchar(50), 
	PERCENTAGE			varchar(50), 
	JOBDESCRIPTION			text, 
	DETAILS			text, 
	BANKACCOUNT			varchar(32), 
	RETIRED			varchar(3), 
	EXTRANSSF			FLOAT, 
	EMAIL			varchar(120), 
	LOANACCOUNT			varchar(25)
);

CREATE TABLE EMPLOYEEMONTH (
	id						serial primary key,
	EMPLOYEEMONTHID			integer, 
	EMPLOYEEID			integer, 
	MONTHRATEID			integer, 
	BANKID			integer, 
	BRANCHID			integer, 
	DEPARTMENTID			integer, 
	ISPERMANENT			varchar(3), 
	ISHOUSED			varchar(3), 
	HOUSERATE			FLOAT, 
	GRADE			varchar(12), 
	MINRANGE			integer, 
	MAXRANGE			integer, 
	PERCENTAGE			FLOAT, 
	BASICPAY			FLOAT, 
	TOTALHOURSPAY			FLOAT, 
	ALLOWANCES			FLOAT, 
	DEDUCTIONS			FLOAT, 
	OVERTIME			FLOAT, 
	NHIFALLOW			FLOAT, 
	NSSFALLOW			FLOAT, 
	TAXALLOW			FLOAT, 
	NHIF			FLOAT, 
	NSSF			FLOAT, 
	TAX			FLOAT, 
	ISNHIF			varchar(3), 
	ISNSSF			varchar(3), 
	ADVANCE			FLOAT, 
	FINALPAY			FLOAT, 
	PAYBALANCE			FLOAT, 
	RETIRECONTRIB			FLOAT, 
	COMMENTS			text, 
	RETIRED			varchar(3), 
	EXTRANSSF			FLOAT
);

CREATE TABLE ALLOWDEFAULT (
	id						serial primary key,
	ALLOWDEFAULTID			integer, 
	EMPLOYEEID			integer, 
	ALLOWANCEID			integer, 
	AMOUNT			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE DEDUCTDEFAULT (
	id						serial primary key,
	DEDUCTDEFAULTID			integer, 
	EMPLOYEEID			integer, 
	DEDUCTIONID			integer, 
	AMOUNT			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE MONTHRATES (
	id						serial primary key,
	MONTHRATEID			integer, 
	RYEAR			varchar(50), 
	RMONTH			varchar(25), 
	ACCPERIOD			varchar(50), 
	STARTDATE			DATE, 
	ENDDATE			DATE, 
	OVERTIME			FLOAT, 
	SPECIALTIME			FLOAT, 
	WORKHOURS			FLOAT, 
	NHIFALLOWANCE			FLOAT, 
	NSSFALLOWANCE			FLOAT, 
	TAXALLOWANCE			FLOAT, 
	NHIFACCOUNT			varchar(50), 
	NSSFACCOUNT			varchar(50), 
	TAXACCOUNT			varchar(50), 
	HRENTACCOUNT			varchar(50), 
	RETIRECONTRIB			FLOAT, 
	ACTIVATED			varchar(3), 
	ISPOLULATED			varchar(3), 
	ISALLOW			varchar(3), 
	ISDEDUCT			varchar(3), 
	ACTIVITIES			text, 
	ISTITHE			varchar(3), 
	JV1			integer, 
	JV2			integer, 
	CHQ			integer, 
	BANKACCOUNT			varchar(50), 
	ISLOANS			varchar(3), 
	INTERESTACC			varchar(30), 
	PCHQ			integer
);

CREATE TABLE EMPLOYEEDEDUCT (
	id						serial primary key,
	EMPLOYEEDEDUCTID			integer, 
	EMPLOYEEMONTHID			integer, 
	DEDUCTIONID			integer, 
	PAYDATE			DATE, 
	AMOUNT			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE JOBRATES (
	id						serial primary key,
	JOBRATEID			integer, 
	JOBID			varchar(3), 
	MONTHRATEID			integer, 
	RATE			FLOAT, 
	OVERTIMERATE			FLOAT, 
	SPECIALTIMERATE			FLOAT, 
	MONTHBUDGET			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE DAYSWORK (
	id						serial primary key,
	DAYSWORKID			integer, 
	MONTHRATEID			integer, 
	WORKDATE			DATE, 
	COMMENTS			varchar(240)
);

CREATE TABLE WORKHOURS (
	id						serial primary key,
	WORKHOURID			integer, 
	DAYSWORKID			integer, 
	EMPLOYEEID			integer, 
	JOBID			varchar(3), 
	COMPLETED			varchar(3), 
	WORKED			FLOAT, 
	OVERTIME			FLOAT, 
	SPECIALTIME			FLOAT
);

CREATE TABLE LOANS (
	id						serial primary key,
	LOANID			integer, 
	EMPLOYEEID			integer, 
	DEDUCTIONID			integer, 
	LOANACCOUNT			varchar(30), 
	AMOUNT			FLOAT, 
	INTEREST			FLOAT, 
	PAYMENTPERIOD			integer, 
	DATEBORROWED			timestamp, 
	ISCHARGED			varchar(3), 
	ISCLEARED			varchar(3), 
	COMMENTS			varchar(120)
);

CREATE TABLE EMPLOYEEALLOW (
	id						serial primary key,
	EMPLOYEEALLOWID			integer, 
	EMPLOYEEMONTHID			integer, 
	ALLOWANCEID			integer, 
	PAYDATE			DATE, 
	AMOUNT			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE EMPLOYEELEAVE (
	id						serial primary key,
	EMPLOYEELEAVEID			integer, 
	EMPLOYEEMONTHID			integer, 
	LEAVETYPE			varchar(50), 
	LEAVEFROM			DATE, 
	LEAVETO			DATE, 
	AMOUNT			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE EMPLOYEEOT (
	id						serial primary key,
	EMPLOYEEOTID			integer, 
	EMPLOYEEMONTHID			integer, 
	OTDATE			DATE, 
	OVERTIME			FLOAT, 
	SPECIALTIME			FLOAT, 
	COMMENTS			varchar(120)
);

CREATE TABLE BANKBRANCH (
	id						serial primary key,
	BANKBRANCHID			varchar(12), 
	BANKID			integer, 
	BRANCHID			integer
);

CREATE TABLE LOANPAYMENT (
	id						serial primary key,
	LOANPAYMENTID			integer, 
	EMPLOYEEMONTHID			integer, 
	LOANACCOUNT			varchar(30), 
	AMOUNT			FLOAT, 
	INTEREST			FLOAT, 
	ISCHARGED			varchar(3), 
	COMMENTS			varchar(120)
);

