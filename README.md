# baraza
Open source HR and Payroll system

In current competitive business environment, Human Capital is core in the organization and this is the new phase of Enterprise.
Human capital is a collection of resources—all the knowledge, talents, skills, abilities, experience, intelligence, training, judgment, and wisdom possessed individually and collectively by individuals in an organization.

Our system allows organizations to manage it's Human Capital optimally for highest optimal output to each individual and do this with clear organizational harmony to achieve value and profit for the organization.
<hr/>

## Features

#### Self Service Desk
- Dashboard
- Employee Details
- Staff out of office/on leave
- Apply For Leave
- Job openings/Internships applications
- Generate CV
- Generate Payslips
- Petty Cash Management
- Employee Tasks on Projects
 	
#### Human Resource Management
- Employee bio data management
- Full Employee profile with automated CV Generation
- Leave management
- Performance management
- Posting of available vacancies
- Training scheduling
- Disciplinary issues and their actions

#### Defitions of:
- Organizations and Locations/Branches
- Departments
- Job roles 
- Banks and their Branches
- News and Emails
- Entities and Salary Scales
- Approval(s) workflow

#### Payroll
- Customisable payroll management
- Configure Allowances, Deductions
- Define Statutory Deductions
- Allowances, Deductions and Taxes calculations
- Payslip generation
- Expenses
- Loans and Advances Management
- Claims and reimbursements

#### Projects
- Project definition
- Phase and task definition and allocation
- Timesheet based on tasks
- Budget estimation
- Project Expenditure management
- Attendance Management

#### Finance
- Budget Allocation
- Raise Invoices 
- Manage Sales and Purchases 
- Manage Payments and Receipts 
- Requisition Management
- Automatic Posting to Journal

#### Reports
- Customisable reports for ease of audit
- Staff Reports
- Review Reports
- Leave, Employees, Contracts, Arbitration etc
<hr/>

## Setup

1. install Postgresql http://www.postgresql.org/ above version 9.0
	
	**Linux Installation**

	`yum install postgresql-server`

	`service postgresql initdb` - (Optional - will clear all databases)
	
	`service postgresql start`

	**Windows Installation**
	
	Download the setup file and install
	
	*To make the installation easier you can set the password for user postgres during the installation to Baraza2011. Remember to change it for a live deployment*

2. install Java 

	http://www.oracle.com/technetwork/java/javase/downloads/index.html version 1.6.30 and above

3. Download hcm.app.3.0.beta1.zip and unzip it on any folder

4. Run the Setup

	`cd ./hcm.app.3.0.2.zip/`
	
	Linux : `./setup.sh`
	
	Windows : double click on setup.bat in app folder

5. Click on 

	Test Connection - {To test connection to the database}
	
	Save Configurations - {In case you change user name or password connecting to the database }
	
	Create New - {Create a new blank database}
	
	Create Demo - {Create a demo database}

6. Running the appplication

	**Web Application**
	
	Linux : `sh server.sh`
	
	Windows : `baraza.bat`
	
	go to browser http://localhost:9090/hr

	**Application**
	
	Linux : `sh baraza.sh`
	
	Windows : `baraza.bat`

	**IDE Application**
	
	Linux : `sh ide.sh`
	
	Windows : `ide.bat`

7. If you have many applications to run in tomcat downlaod the hcm.3.0.2.war 
8. No DB configuration will be needed. There is a README file for the .war in the war folder

#### USER PASSWORDS

username `root`
password `baraza`

#### DEMO Accounts

Applicants

dennisgichangi@gmail.com - baraza

Employees

dc.joseph.kamau - baraza
