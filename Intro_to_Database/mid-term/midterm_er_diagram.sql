use f22_midterm;
drop database if exists f22_midterm;

create database f22_midterm;

set foreign_key_checks = 0;
drop table if exists f22_midterm.employee;
drop table if exists f22_midterm.project;
drop table if exists f22_midterm.project_team;
set foreign_key_checks = 1;

create table f22_midterm.employee
(
    employee_id    char(4)                                  not null,
    last_name      varchar(64)                              not null,
    first_name     varchar(64)                              not null,
    employee_type  enum ('regular', 'manager', 'executive') not null,
    employee_email varchar(20)                              null,
    constraint employee_pk
        primary key (employee_id),
    constraint employee_unik
        unique (employee_email),
    constraint employee_id
        check (
                length(employee_id) = 4
                and employee_id REGEXP '^[0-9]+$'
                )
);

create table f22_midterm.project
(
    project_code char(2)     not null,
    project_name varchar(32) not null,
    constraint project_pk
        primary key (project_code),
    constraint project_code
        check (CAST(project_code AS BINARY) REGEXP BINARY '^[A-Z]+$'
            and length(project_code) = 2)
);

create table f22_midterm.project_team
(
    project_code char(2) not null,
    sponsor_id   char(4) not null,
    manager_id   char(4) not null,
    employee_id  char(4) not null,
    constraint project_team_pk
        primary key (sponsor_id, manager_id),
    constraint project_team_unik
        unique (project_code),
    constraint project_team_employee_employee_null_fk
        foreign key (employee_id) references f22_midterm.employee (employee_id),
    constraint project_team_employee_manager_null_fk
        foreign key (manager_id) references f22_midterm.employee (employee_id),
    constraint project_team_employee_sponsor_null_fk
        foreign key (sponsor_id) references f22_midterm.employee (employee_id),
    constraint project_team_project_null_fk
        foreign key (project_code) references f22_midterm.project (project_code)
);

drop trigger if exists fk_employee_id_insert_trigger;
create trigger fk_employee_id_insert_trigger before insert on project_team
    for each row
    BEGIN
        declare v_employee_id_type enum ('regular', 'manager', 'executive');
        declare v_manager_id_type enum ('regular', 'manager', 'executive');
        declare v_sponsor_id_type enum ('regular', 'manager', 'executive');

        set v_employee_id_type = (select
                                    a.employee_type
                                from employee a
                                where a.employee_id = NEW.employee_id
                                );
        set v_manager_id_type = (select
                                    a.employee_type
                                from employee a
                                where a.employee_id = NEW.manager_id
                                );
        set v_sponsor_id_type = (select
                                    a.employee_type
                                from employee a
                                where a.employee_id = NEW.sponsor_id
                                );
        if v_employee_id_type <> 'regular'
            then signal sqlstate '77777'
                set message_text = "Can't insert since employee_id is not an employee";
        elseif v_manager_id_type <> 'manager'
            then signal sqlstate '77777'
                set message_text = "Can't insert since manager_id is not a manager";
        elseif v_sponsor_id_type <> 'executive'
            then signal sqlstate '77777'
                set message_text = "Can't insert since sponsor_id is not an executive";
        end if;
    END;

drop trigger if exists fk_employee_id_update_trigger;
create trigger fk_employee_id_update_trigger before update on project_team
    for each row
    BEGIN
        declare v_employee_id_type enum ('regular', 'manager', 'executive');
        declare v_manager_id_type enum ('regular', 'manager', 'executive');
        declare v_sponsor_id_type enum ('regular', 'manager', 'executive');

        set v_employee_id_type = (select
                                    a.employee_type
                                from employee a
                                where a.employee_id = NEW.employee_id
                                );
        set v_manager_id_type = (select
                                    a.employee_type
                                from employee a
                                where a.employee_id = NEW.manager_id
                                );
        set v_sponsor_id_type = (select
                                    a.employee_type
                                from employee a
                                where a.employee_id = NEW.sponsor_id
                                );
        if v_employee_id_type <> 'regular'
            then signal sqlstate '77777'
                set message_text = "Can't update since employee_id is not an employee";
        elseif v_manager_id_type <> 'manager'
            then signal sqlstate '77777'
                set message_text = "Can't update since manager_id is not a manager";
        elseif v_sponsor_id_type <> 'executive'
            then signal sqlstate '77777'
                set message_text = "Can't update since sponsor_id is not an executive";
        end if;
    END;

drop trigger if exists multiple_employee_id_insert_trigger;
create trigger multiple_employee_id_insert_trigger before insert on project_team
    for each row
    BEGIN
        declare count_e INT;
        declare count_m INT;
        declare count_s INT;

        set count_e = (select count(a.employee_id) from project_team a where a.employee_id = NEW.employee_id);
        set count_m = (select count(a.employee_id) from project_team a where a.manager_id = NEW.manager_id);
        set count_s =  (select count(a.employee_id) from project_team a where a.sponsor_id = NEW.sponsor_id);

        if count_e >=3
            then signal sqlstate '88888'
                set message_text = "Can't insert since this employee already has three projects";
        elseif count_m >=3
            then signal sqlstate '88888'
                set message_text = "Can't insert since this manager already has three projects";
        elseif count_s >=3
            then signal sqlstate '88888'
                set message_text = "Can't insert since this executive already has three projects";
        end if;
    END;

drop trigger if exists multiple_employee_id_update_trigger;
create trigger multiple_employee_id_update_trigger before update on project_team
    for each row
    BEGIN
        declare count_e INT;
        declare count_m INT;
        declare count_s INT;

#         set count_e = (select count(*) where OLD.employee_id = NEW.employee_id);
#         set count_e = (select count(*) where OLD.manager_id = NEW.manager_id);
#         set count_e = (select count(*) where OLD.sponsor_id = NEW.sponsor_id);
        set count_e = (select count(a.employee_id) from project_team a where a.employee_id = NEW.employee_id);
        set count_m = (select count(a.employee_id) from project_team a where a.manager_id = NEW.manager_id);
        set count_s =  (select count(a.employee_id) from project_team a where a.sponsor_id = NEW.sponsor_id);

        if count_e >=3
            then signal sqlstate '88888'
                set message_text = "Can't update since this employee already has three projects";
        elseif count_m >=3
            then signal sqlstate '88888'
                set message_text = "Can't update since this manager already has three projects";
        elseif count_s >=3
            then signal sqlstate '88888'
                set message_text = "Can't update since this executive already has three projects";
        end if;
    END;

insert into project (project_code, project_name)
values ('AA','about');
insert into project (project_code, project_name)
values ('BB','about');
insert into project (project_code, project_name)
values ('CC','about');
insert into project (project_code, project_name)
values ('DD','about');
insert into project (project_code, project_name)
values ('EE','about');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('1001','zhou','wei','regular','@a');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('1002','zhou','wei','regular','@b');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('1003','zhou','wei','regular','@c');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('2001','zhou','wei','manager','@d');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('2002','zhou','wei','manager','@e');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('2003','zhou','wei','manager','@g');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('2004','zhou','wei','manager','@h');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('3001','zhou','wei','executive','@f');
insert into employee (employee_id, last_name, first_name, employee_type, employee_email)
values ('3002','zhou','wei','executive','@i');

insert into project_team (project_code, sponsor_id, manager_id, employee_id)
values ('AA','3001','2001','1001');
insert into project_team (project_code, sponsor_id, manager_id, employee_id)
values ('BB','3001','2002','1001');
insert into project_team (project_code, sponsor_id, manager_id, employee_id)
values ('CC','3001','2003','1001');
insert into project_team (project_code, sponsor_id, manager_id, employee_id)
values ('EE','3002','2004','1002');
update project_team
set employee_id = '1001'
where employee_id = '1002';
# insert into project_team (project_code, sponsor_id, manager_id, employee_id)
# values ('DD','3001','2004','1001');
SHOW TRIGGERS;

select * from project_team;

