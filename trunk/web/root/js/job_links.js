$(document).ready(function() {

    $('.deletejob').click(function(element) {
        $.ajax({
            type: 'DELETE',
            url: element.target,
            contentType: 'text/html',
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.startjob').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'start' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.resumejob').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'resume' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.pausejob').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'pause' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.stopjob').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'stop' },
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

    $('.killjob').click(function(element) {
        $.ajax({
            type: 'POST',
            url: element.target,
            contentType: 'application/x-www-form-urlencoded',
            data: { action: 'kill' }
        }).done(function(data, status, jqxhr) {
            $('body').html(data);
        }).fail(function(jqxhr, status, error) {
            $('body').html(jqxhr.responseText);
        });
    });

});

