# Integration Tests Setup

This document outlines the steps required to set up the environment for running integration tests for our project.

## Module

- test

## Prerequisites

Maven Dependencies:

- Add following Maven dependencies are included in your `pom.xml` file:

```xml

<dependency>
    <groupId>io.cucumber</groupId>
    <artifactId>cucumber-java</artifactId>
    <version>7.18.1</version>
    <scope>test</scope>
</dependency>

<dependency>
<groupId>io.cucumber</groupId>
<artifactId>cucumber-picocontainer</artifactId>
<version>7.18.1</version>
<scope>test</scope>
</dependency>
<dependency>
<groupId>io.cucumber</groupId>
<artifactId>cucumber-junit-platform-engine</artifactId>
<version>7.18.1</version>
<scope>test</scope>
</dependency>
<dependency>
<groupId>org.junit.platform</groupId>
<artifactId>junit-platform-suite</artifactId>
<version>1.11.2</version>
<scope>test</scope>
</dependency>
<dependency>
<groupId>com.typesafe</groupId>
<artifactId>config</artifactId>
<version>1.4.3</version>
</dependency>
<dependency>
<groupId>io.rest-assured</groupId>
<artifactId>rest-assured</artifactId>
<version>5.5.0</version>
<scope>test</scope>
</dependency>
<dependency>
<groupId>org.testcontainers</groupId>
<artifactId>testcontainers</artifactId>
<version>1.17.6</version>
<scope>test</scope>
</dependency>


```